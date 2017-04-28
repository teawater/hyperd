#!/bin/python

import sys
import leveldb
import json

db = leveldb.LevelDB('/var/lib/hyper/lib/hyper.db')

# list all key and value
#for key, value in db.RangeIter():
#        print (key, value);

# check argument
if len(sys.argv) != 3:
  print "%s <pod-id> <property>" % sys.argv[0]
  print "<property>: hostname | device | vmid"
  sys.exit(1)  

# genereate key
pod_id = sys.argv[1]
key = "SB-%s" % pod_id
#print "Get value of key: %s" % (key)

# get property
property_name = sys.argv[2]
if property_name not in ["hostname", "device", "vmid"]:
  print "unknown property %s" % property_name
  sys.exit(2)

try:
  # get value of key
  value = db.Get(key)
  #print  str(value[value.find("{"):])
except:
  print "can not get value of key:%s" % key
  sys.exit(3)

try:
  d = json.loads(str(value[value.find("{"):]))
  if property_name == "hostname":
    if d["VmSpec"] and d["VmSpec"]["hostname"]:
      print "%s" % d["VmSpec"]["hostname"]
  elif property_name == "device":
    for i in d["VolumeList"]:
      if i["Format"] == "raw":
        print "%s" % i["Name"]
  elif property_name == "vmid":
    print "%s" % d["Id"]
  else:
    print "unknow property: %s" % property_name
    sys.exit(4)
except:
  print "get property from json failed:%s" % str(value[value.find("{"):])
  sys.exit(5)

