package stress

import (
  "fmt"
)

func stressMemory(s int64) {
  x := [][]byte{}
	x = append(x, make([]byte, s*1024*1024))
	defer fmt.Println("memory stress finished")
}
