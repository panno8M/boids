import gdext
import gdext/classes/gdNode
import gdext/classes/gdEngine
import gdext/classes/gdGodotThread
import gdext/classes/gdResource

const NotificationServerEnabled = hostOS == "linux"

type
  Notification* {.gdsync.} = ptr object of Resource
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
    NotificationServer* {.gdsync.} = ptr object of Node
      dbusthread: gdref GodotThread

    Context = object
      self: NotificationServer
      lastNotificationID: uint32
      bus: Bus

  proc notificationRecieved*(self: NotificationServer; notification: Notification): Error {.gdsync, signal.}
  proc publishNotification*(self: NotificationServer; notification: Notification) {.gdsync.} =
    discard self.notificationRecieved(notification)

  proc notify(context: ptr Context; incoming: IncomingMessage): bool =
    echo "[Notify] received notification"
    var args = incoming.unpackValueSeq
    let n = instantiate Notification
    n[].appName = String(args[0].asNative string)
    n[].replacesId = Int(args[1].asNative uint32)
    n[].summary = String(args[3].asNative string)
    n[].body = String(args[4].asNative string)
    n[].expireTimeout = Int(args[7].asNative int32)
    context.self.callable"publish_notification".callDeferred(n)
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

  proc serve(self: NotificationServer) {.gdsync.} =
    dbus.loadAPI()
    let context = create(Context)
    defer: dealloc context

    context.self = self
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
    self.dbusthread = instantiate(GodotThread)
    discard self.dbusthread[].start(self.callable"serve")
  else:
    print "NotificationServer Disabled"
