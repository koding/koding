package stack

import (
	"math/rand"
	"os"
	"sync"
	"time"
)

var (
	r   = rand.New(rand.NewSource(time.Now().UnixNano() + int64(os.Getpid())))
	rmu sync.Mutex // rand.NewSource is not goroutine safe
)

// pokemons is a list of pokemon names stolen from:
//
//   client/app/lib/util/getPokemonName.coffee
//
// see todo for JStackTemplate.create at:
//
//   workers/social/lib/social/models/computeproviders/stacktemplate.coffee:198
//
// on how to get rid of this duplication.
var pokemons = []string{
	"Bulbasaur", "Ivysaur", "Venusaur", "Charmander", "Charmeleon", "Charizard",
	"Squirtle", "Wartortle", "Blastoise", "Caterpie", "Metapod", "Butterfree",
	"Weedle", "Kakuna", "Beedrill", "Pidgey", "Pidgeotto", "Pidgeot", "Rattata",
	"Raticate", "Spearow", "Fearow", "Ekans", "Arbok", "Pikachu", "Raichu",
	"Sandshrew", "Sandslash", "Nidoran", "Nidorina", "Nidoqueen", "Nidoran",
	"Nidorino", "Nidoking", "Clefairy", "Clefable", "Vulpix", "Ninetales",
	"Jigglypuff", "Wigglytuff", "Zubat", "Golbat", "Oddish", "Gloom",
	"Vileplume", "Paras", "Parasect", "Venonat", "Venomoth", "Diglett",
	"Dugtrio", "Meowth", "Persian", "Psyduck", "Golduck", "Mankey", "Primeape",
	"Growlithe", "Arcanine", "Poliwag", "Poliwhirl", "Poliwrath", "Abra",
	"Kadabra", "Alakazam", "Machop", "Machoke", "Machamp", "Bellsprout",
	"Weepinbell", "Victreebel", "Tentacool", "Tentacruel", "Geodude", "Graveler",
	"Golem", "Ponyta", "Rapidash", "Slowpoke", "Slowbro", "Magnemite",
	"Magneton", "Farfetch", "Doduo", "Dodrio", "Seel", "Dewgong", "Grimer",
	"Muk", "Shellder", "Cloyster", "Gastly", "Haunter", "Gengar", "Onix",
	"Drowzee", "Hypno", "Krabby", "Kingler", "Voltorb", "Electrode", "Exeggcute",
	"Exeggutor", "Cubone", "Marowak", "Hitmonlee", "Hitmonchan", "Lickitung",
	"Koffing", "Weezing", "Rhyhorn", "Rhydon", "Chansey", "Tangela",
	"Kangaskhan", "Horsea", "Seadra", "Goldeen", "Seaking", "Staryu", "Starmie",
	"Mr. Mime", "Scyther", "Jynx", "Electabuzz", "Magmar", "Pinsir", "Tauros",
	"Magikarp", "Gyarados", "Lapras", "Ditto", "Eevee", "Vaporeon", "Jolteon",
	"Flareon", "Porygon", "Omanyte", "Omastar", "Kabuto", "Kabutops",
	"Aerodactyl", "Snorlax", "Articuno", "Zapdos", "Moltres", "Dratini",
	"Dragonair", "Dragonite", "Mewtwo", "Mew",
}

func Pokemon() string {
	rmu.Lock()
	n := r.Int31n(int32(len(pokemons)))
	rmu.Unlock()

	return pokemons[n]
}
