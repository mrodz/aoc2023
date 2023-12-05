#include <game_reader.h>
#include <game.h>
#include <stdlib.h>

#define CAPACITY 2

int main(int argc, char *const argv[]) {
	game games[CAPACITY];

	games_from_path(games, CAPACITY, "./input/sample.txt");

	return EXIT_SUCCESS;
}