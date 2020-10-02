package main

import (
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"runtime"
	"syscall"
)

var (
	apiport = ":6789"
	staticport = ":9876"
	path = "."
)

func open(url string) error {
	var cmd string
	var args []string

	switch runtime.GOOS {
	case "windows":
		cmd = "cmd"
		args = []string{"/c", "start"}

	case "darwin":
		cmd = "open"

	default: // "linux", "freebsd", "openbsd", "netbsd"
		cmd = "xdg-open"
	}

	args = append(args, url)

	return exec.Command(cmd, args...).Start()
}

func waitcancel() {
	sig := make(chan os.Signal)
	signal.Notify(sig, os.Interrupt, syscall.SIGTERM)

	go func() {
		println("Press Ctrl+C to stop")
		<-sig
		println("\nhej då!")
		os.Exit(0)
	}()

	select { }
}

func main() {
	e, err := os.Executable()
	if err != nil {
		panic(err)
	}

	path = filepath.Dir(e)
	println(path)

	go api()
	go static()

	open("http://localhost"+staticport)

	waitcancel()
}
