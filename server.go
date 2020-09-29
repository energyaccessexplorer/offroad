package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
)

var (
	port int
	ip   string
)

func fileServerHandler(w http.ResponseWriter, r *http.Request) {
	http.FileServer(http.Dir("sources")).ServeHTTP(w,r)
}

func Start() {
	flag.IntVar(&port, "port", 9876, "Port on which it the server will run.")
	flag.StringVar(&ip, "ip", "localhost", "IP address which the server will listen to.")

	flag.Parse()

	addr := strings.Join([]string{ip, strconv.Itoa(port)}, ":")

	fmt.Println(fmt.Sprintf("Running on: %s", addr))

	http.HandleFunc("/", fileServerHandler)
	log.Fatal(http.ListenAndServe(addr, nil))
}

func main() {
	Start()
}
