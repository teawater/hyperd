package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/syndtr/goleveldb/leveldb"
	"github.com/syndtr/goleveldb/leveldb/opt"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Printf("%v <pod-id>", os.Args[0])
		os.Exit(1)
	}

	db, err := leveldb.OpenFile("/var/lib/hyper/lib/hyper.db.bak", &opt.Options{ReadOnly: true})
	if err != nil {
		panic(fmt.Sprintf("Open hyper.db failed!:%v", err.Error()))
	}
	defer db.Close()

	/*
		iter := db.NewIterator(nil, nil)
		for iter.Next() {
			// Remember that the contents of the returned slice should not be modified, and
			// only valid until the next call to Next.
			key := iter.Key()
			value := iter.Value()
			fmt.Printf("\n\nkey:%q\nvalue:%q",key, value)
		}
		iter.Release()
		err = iter.Error()
		if (err != nil) {
			panic(fmt.Sprintf("Close hyper.db failed!:%v", err.Error()));
		}
	*/

	key := fmt.Sprintf("SB-%v", os.Args[1])
	//fmt.Printf("key: %v\n", key)
	value, err := db.Get([]byte(key), nil)
	if err != nil {
		panic(fmt.Sprintf("Key %v not found(Error:%v)\n", key, err))
	}
	tmp := string(value[:])
	jsonStr := tmp[strings.Index(tmp, "{"):]
	//fmt.Printf("data(%T):%q", jsonStr, jsonStr)

	//convert jsonStr to json
	var data map[string]interface{}
	if err := json.Unmarshal([]byte(jsonStr), &data); err != nil {
		panic(fmt.Sprintf("Can not convert string(%v) to json(Error:%v)\n", jsonStr, err))
	}
	//fmt.Printf("(%T) %v\n", data["VolumeList"], data["VolumeList"])

	item := data["VolumeList"]
	if rec, ok := item.([]interface{}); ok {
		for _, val := range rec {
			if val.(map[string]interface{})["Format"] == "raw" {
				fmt.Printf("%v", val.(map[string]interface{})["Name"])
			}
		}
	} else {
		fmt.Printf("item not a map[string]interface{}: %v\n\n", item)
	}
}
