package main

import (
	"fmt"
	"net/http"
)

func static() {
	fmt.Println("Running website on localhost"+staticport)
	http.HandleFunc("/", http.FileServer(http.Dir(path+"/build")).ServeHTTP)
	panic(http.ListenAndServe(staticport, nil))
}
