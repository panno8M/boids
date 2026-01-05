import gdext
import gdext/classes/gdNode
import gdext/classes/gdEngine

const NotificationServerEnabled = hostOS == "linux"

type
  Notification* {.gdsync.} = ptr object of Object
    appName* {.gdexport.}: String
    replacesId* {.gdexport.}: Int
    # appIcon*: string
    summary* {.gdexport.}: String
    body* {.gdexport.}: String
    expireTimeout* {.gdexport.}: Int

when NotificationServerEnabled:
  import dbus
  import dbus/loop

  const
    BUS_NAME = "org.freedesktop.Notifications"

  type
    NotificationMessage = object
      appName*: string
      replacesId*: uint32
      appIcon*: string
      summary*: string
      body*: string
      expireTimeout*: int32

    Request = enum
      quit

    NotificationServer* {.gdsync.} = ptr object of Node
      dbusthread: Thread[void]

    Context = object
      lastNotificationID: uint32
      bus: Bus

  var cNotify: Channel[NotificationMessage]
  var cRequest: Channel[Request]

  proc toNotification(msg: NotificationMessage): Notification =
    result = instantiate Notification
    result.appName = msg.appName
    result.replacesId = Int(msg.replacesId)
    result.summary = msg.summary
    result.body = msg.body
    result.expireTimeout = msg.expireTimeout

  proc notify(context: ptr Context; incoming: IncomingMessage): bool =
    echo "[Notify] received notification"
    var args = incoming.unpackValueSeq
    cNotify.send NotificationMessage(
      appName: args[0].asNative(string),
      replacesId: args[1].asNative(uint32),
      appIcon: args[2].asNative(string),
      summary: args[3].asNative(string),
      body: args[4].asNative(string),
      expireTimeout: args[7].asNative(int32),
    )
    inc context.lastNotificationID
    context.bus.sendReply(incoming, @[context.lastNotificationID.asDbusValue])
    true

  proc getCapabilities(context: ptr Context; incoming: IncomingMessage): bool =
    echo "[GetCapabilities]"
    context.bus.sendReply(incoming, @[@["body"].asDbusValue])
    true

  proc getServerInformation(context: ptr Context; incoming: IncomingMessage): bool =
    echo "[GetServerInformation]"
    context.bus.sendReply(incoming, @[
      "Nabula Notification Server".asDbusValue,
      "Nabula".asDbusValue,
      "0.1".asDbusValue,
      "1.2".asDbusValue,
    ])
    true

  proc handleMessage(context: ptr Context; incoming: IncomingMessage): bool =
    let `interface` = incoming.interfaceName
    let member = incoming.name
    case `interface`
    of "org.freedesktop.Notifications":
      case member
      of "Notify":
        notify(context, incoming)
      of "GetCapabilities":
        getCapabilities(context, incoming)
      of "GetServerInformation":
        getServerInformation(context, incoming)
      of "CloseNotification":
        echo "[CloseNotification]"
        context.bus.sendReply(incoming, @[])
        true
      else:
        echo "[Warning] Unknown method: ", member
        context.bus.sendErrorReply(incoming,
          "the member `" & member & "` not implemented",
        )
        true
    else:
      echo "[Warning] Unknown interface: ", `interface`
      context.bus.sendErrorReply(incoming,
        "the interface `" & `interface` & "` not implemented",
      )
      true

  proc serve() {.thread.} =
    let context = create(Context)
    defer: dealloc context

    context.bus = getBus(DBUS_BUS_SESSION)
    context.bus.requestName(BUS_NAME)

    proc handle_notification(typ: IncomingMessageType; incoming: IncomingMessage): bool =
      handleMessage(context, incoming)


    echo "Nabula Notification Server started"

    context.bus.registerObject(
      ObjectPath("/org/freedesktop/Notifications"),
      handle_notification,
    )
    runForever MainLoop.create(context.bus)
else:
  type
    NotificationServer* {.gdsync.} = ptr object of Node

proc notificationRecieved*(self: NotificationServer; notification: Notification): Error {.gdsync, signal.}

method ready*(self: NotificationServer) {.gdsync.} =
  if Engine.isEditorHint: return
  when NotificationServerEnabled:
    echo "Initialize NotificationServer..."
    cNotify.open()
    cRequest.open()
    createThread(self.dbusthread, serve)
  else:
    print "NotificationServer Disabled"

when NotificationServerEnabled:
  method process*(self: NotificationServer; delta: float64) {.gdsync.} =
    let (available, notification) = cNotify.tryRecv()
    if available:
      discard self.notificationRecieved(notification.toNotification)
