package person

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// Person type
type Person struct {
	ID        string   `json:"id,omitempty" bson:"id"`
	Firstname string   `json:"firstname,omitempty" bson:"firstname"`
	Lastname  string   `json:"lastname,omitempty" bson:"lastname"`
	Address   *Address `json:"address,omitempty" bson:"address"`
}

// Address type
type Address struct {
	City  string `json:"city,omitempty" bson:"city"`
	State string `json:"state,omitempty" bson:"state"`
}

var people []Person
var mongoSession *mgo.Session

// Init ...
func Init(session *mgo.Session) {
	if session != nil {
		mongoSession = session
	} else {
		people = append(people, Person{ID: "1", Firstname: "John", Lastname: "Doe", Address: &Address{City: "City X", State: "State X"}})
		people = append(people, Person{ID: "2", Firstname: "Koko", Lastname: "Doe", Address: &Address{City: "City Z", State: "State Y"}})
	}
}

func getCollection() (*mgo.Collection, *mgo.Session) {
	s := mongoSession.Copy()
	c := s.DB("test").C("people")

	return c, s
}

// GetAll person objects
func GetAll(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if mongoSession != nil {
		// get all person from mongodb
		c, s := getCollection()
		defer s.Close()

		result := []Person{}
		err := c.Find(nil).All(&result)
		if err != nil {
			log.Printf("RunQuery : ERROR : %s\n", err)
			return
		}

		json.NewEncoder(w).Encode(result)

	} else {
		json.NewEncoder(w).Encode(people)
	}
}

// Get a person object
func Get(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	params := mux.Vars(r)

	if mongoSession != nil {
		// find the person from mongodb
		c, s := getCollection()
		defer s.Close()

		p := Person{}
		err := c.Find(bson.M{"id": params["id"]}).One(&p)
		if err != nil {
			log.Printf("RunQuery : ERROR : %s\n", err)
			return
		}
		json.NewEncoder(w).Encode(p)

	} else {
		// find the person from the people slice
		for _, p := range people {
			if p.ID == params["id"] {
				json.NewEncoder(w).Encode(p)
				return
			}
		}
	}
}

// Create a person object
func Create(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	var p Person
	_ = json.NewDecoder(r.Body).Decode(&p)
	p.ID = params["id"]

	if mongoSession != nil {
		c, s := getCollection()
		defer s.Close()

		err := c.Insert(p)
		if err != nil {
			log.Printf("RunQuery : ERROR : %s\n", err)
			return
		}

		GetAll(w, r)
	} else {
		people = append(people, p)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(people)
	}
}

// Delete a person object
func Delete(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)

	if mongoSession != nil {
		c, s := getCollection()
		defer s.Close()

		err := c.Remove(bson.M{"id": params["id"]})
		if err != nil {
			log.Printf("RunQuery : ERROR : %s\n", err)
			return
		}

		GetAll(w, r)
	} else {
		w.Header().Set("Content-Type", "application/json")
		for i, p := range people {
			if p.ID == params["id"] {
				people = append(people[:i], people[i+1:]...)
				break
			}
			json.NewEncoder(w).Encode(people)
		}
	}
}

// Update a person object
func Update(w http.ResponseWriter, r *http.Request) {
	params := mux.Vars(r)
	var p Person
	_ = json.NewDecoder(r.Body).Decode(&p)
	p.ID = params["id"]

	if mongoSession != nil {
		c, s := getCollection()
		defer s.Close()

		err := c.Update(bson.M{"id": params["id"]}, &p)
		if err != nil {
			log.Printf("RunQuery : ERROR : %s\n", err)
			return
		}

		GetAll(w, r)
	} else {
		// remove the matched person from the slice
		for i, p := range people {
			if p.ID == params["id"] {
				// this approach is supposed to be memory leak free when
				// the element of the slice is a pointer or a struct with pointer fields.
				// since the slice here is non of that, we don't have to use this, but
				// I am leaving this bit of code here just for reference.
				// (https://github.com/golang/go/wiki/SliceTricks)
				copy(people[i:], people[i+1:])
				people[len(people)-1] = Person{}
				people = people[:len(people)-1]
				break
			}
		}
		// add the updated person back into the slice
		people = append(people, p)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(people)
	}
}
