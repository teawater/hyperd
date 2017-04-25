#!/bin/python

import sys
import leveldb
import json

db = leveldb.LevelDB('/var/lib/hyper/lib/hyper.db')

# list all key and value
#for key, value in db.RangeIter():
#        print (key, value);

# check argument
if len(sys.argv) != 2:
  print "%s <pod-id>" % (sys.argv[0])
  sys.exit(1)  

# genereate key
pod_id = sys.argv[1]
key = "SB-%s" % (pod_id)
#print "Get value of key: %s" % (key)

try:
  # get value of key
  value = db.Get(key)
  #print  str(value[value.find("{"):])
except:
  sys.exit(2)

try:
  d = json.loads(str(value[value.find("{"):]))
  for i in d["VolumeList"]:
    if i["Format"] == "raw":
      print i["Name"]
except:
  sys.exit(3)


