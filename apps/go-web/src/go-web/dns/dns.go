package dns

import (
  "context"
  "fmt"
  "math/rand"
  "net"
  "sync"
  "time"
  "net/http"
  "strconv"
)

const letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

func randString(n int) string {
  b := make([]byte, n)
  for i := range b {
    b[i] = letters[rand.Intn(len(letters))]
  }
  return string(b)
}

func resolveDns(c int64, d string) error {
  rand.Seed(time.Now().UnixNano())
  errCount := 0

  wg := sync.WaitGroup{}
  for i := int64(1); i <= c; i++ {
    wg.Add(1)
    go func() {
      defer wg.Done()
      res := &net.Resolver{PreferGo: true}
      cntx := context.Background()

      domain := ""
      if d == "" {
        domain = randString(6)
      } else {
        domain = d
      }

      _, err := res.LookupIPAddr(cntx, domain)
      if err != nil {
        errCount += 1
        fmt.Println(err)
      }
    }()
  }
  wg.Wait()

  if errCount > 0 {
    return fmt.Errorf("Failed to resolve %d FQDN(s)", errCount)
  }
  return nil
}

func Run(w http.ResponseWriter, r *http.Request) {
  weight := int64(10)

  weightValue := r.FormValue("weight")
  if weightValue != "" {
    weight, _ = strconv.ParseInt(weightValue,0,64)
  }

  domain := r.FormValue("domain")

  err := resolveDns(weight, domain)

  if err != nil {
    http.Error(w, fmt.Sprintf("500 - %s", err), http.StatusInternalServerError)
  } else {
    w.WriteHeader(http.StatusOK)
    fmt.Fprintf(w, "Weight: %d\n", weight)
  }
}
