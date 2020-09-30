package main

import (
	"fmt"
	"log"
	"net/http"
)

var (
	port int
	ip   string
)

func api() {
	mux := http.NewServeMux()

	fmt.Println("Running \"api\" on localhost:6789")
	http.ListenAndServe(":6789", mux)
}

func static() {
	fmt.Println("Running website on localhost:9867")

	http.HandleFunc("/", http.FileServer(http.Dir("sources")).ServeHTTP)
	log.Fatal(http.ListenAndServe(":9876", nil))
}

func main() {
	go api()
	static()
}
