#define DEBUG_IO

#include <game_reader.h>
#include <game.h>
#include <stdlib.h>

#define CAPACITY 4

int main(int argc, char *const argv[]) {
	game games[CAPACITY];
	game_reader_settings settings = { .verbose = 0, /*.width_of_newline = 1*/ };

	games_from_path(games, CAPACITY, "./input/sample.txt", &settings);

	return EXIT_SUCCESS;
}