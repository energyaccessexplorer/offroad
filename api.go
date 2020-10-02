package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
)

type reswr = http.ResponseWriter

type req = *http.Request

var _ID string

func wrp(h func(req) (string)) func(reswr, req) {
	_ID = ""

	return func(w reswr, r req) {
		w.Header().Set("Access-Control-Allow-Origin", "http://localhost:9876")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		w.Header().Set("Content-Type", "application/json")

		switch r.Method {
		case "OPTIONS":
			w.Header().Set("Allow", "GET")

		case "GET":
			send(h(r), w)
		}
	}
}

func eq(s string, r req) (ok bool) {
	q := r.URL.Query()

	if q[s] != nil && strings.HasPrefix(q[s][0], "eq.") {
		_ID = q[s][0][3:]
		ok = true
	}

	return
}

func send(f string, w reswr) string {
	w.Header().Set("Content-Type", "application/octet-stream")

	file, err := os.Open(path + "/data/" + f)
	if err != nil {
		http.Error(w, "Could not open file "+f, 404)
	}

	bytes, _ := ioutil.ReadAll(file)
	w.Write(bytes)

	return string(bytes)
}

func geographies(r req) (s string) {
	if eq("id", r) {
		s = "geographies/"+_ID
	} else {
		s = "geographies/all.json"
	}

	return
}

func boundaries(r req) (s string) {
	if eq("geography_id", r) {
		s = "boundaries/"+_ID
	}

	return
}

func datasets(r req) (s string) {
	if eq("id", r) {
		s = "datasets/"+_ID
	}

	if eq("geography_id", r) {
		s = "datasets/"+_ID
	}

	return
}

func files(r req) (s string) {
	s = r.URL.String()
	return
}

func api() {
	mux := http.NewServeMux()

	mux.HandleFunc("/geography_boundaries", wrp(boundaries))
	mux.HandleFunc("/geographies", wrp(geographies))
	mux.HandleFunc("/datasets", wrp(datasets))
	mux.HandleFunc("/files/", wrp(files))

	fmt.Println("Running \"api\" on localhost"+apiport)
	http.ListenAndServe(apiport, mux)
}
