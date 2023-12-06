#define DEBUG_IO

#include <game.h>
#include <game_reader.h>

#include <stdlib.h>

#define CAPACITY 100
#define MAX_RED 12
#define MAX_GREEN 13
#define MAX_BLUE 14

int main(int argc, const char *argv[])
{
	game games[CAPACITY];
	game_reader_settings settings = {.verbose = 0, /*.width_of_newline = 1*/};

	games_from_path(games, CAPACITY, "./input/input.txt", &settings);

	int sum = 0;

	for (int i = 0; i < CAPACITY; i++)
	{
		if (game_is_valid(games + i, MAX_RED, MAX_GREEN, MAX_BLUE))
		{
			int id = games[i].id;
			sum += id;
		}

		game_cleanup(games + i);
	}

	printf("%d", sum);

	return EXIT_SUCCESS;
}