import gdext
import gdext/nameformats
import classes/gdBoidController3D
import classes/gdBoidSpawner3D
import classes/gdBoidSpawnerFixed3D
import classes/gdBoidSpawnerFpsAdaptive3D
import classes/gdBoidRuleCohesion3D
import classes/gdBoidRuleSeparation3D
import classes/gdBoidRuleAlignment3D
import classes/gdBoidRuleAvoidGrid3D
import classes/gdBoidRuleStayInBounds3D
import classes/gdBoidRuleInteractNode3D
import classes/gdBoidRuleFollowNode3D
import classes/gdBoidRulePostureLookAt3D
import classes/gdTerminal
import nabula/archives
import notifications/gdNotificationServer

proc set_formatters {.execon: EntryPoint.} =
  defaultPropertyFormatter = toSnakeCase
  defaultFunctionFormatter = toSnakeCase
  defaultVirtualMethodFormatter = toGodotInternalFuncCase

GDExtensionEntryPoint
