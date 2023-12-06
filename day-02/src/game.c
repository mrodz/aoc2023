#include <game.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int game_is_valid(const game *game, int r, int g, int b)
{
	int rsum = 0, gsum = 0, bsum = 0;

	for (game_node *node = game->start; node != NULL; node = node->next)
	{
		switch (node->color)
		{
		case RED:
			rsum += node->count;
			break;
		case GREEN:
			gsum += node->count;
			break;
		case BLUE:
			bsum += node->count;
			break;
		}

		if (node->end_of_segment)
		{
			if (rsum > r || gsum > g || bsum > b)
			{
				return 0;
			}

			rsum = gsum = bsum = 0;
		}
	}

	return 1;
}

void game_maxes(const game *game, int *r, int *g, int *b) {
	int rsum = 0, gsum = 0, bsum = 0;
	int rmax = 0, gmax = 0, bmax = 0;

	for (game_node *node = game->start; node != NULL; node = node->next)
	{
		switch (node->color)
		{
		case RED:
			rsum += node->count;
			break;
		case GREEN:
			gsum += node->count;
			break;
		case BLUE:
			bsum += node->count;
			break;
		}

		if (node->end_of_segment)
		{
			rmax = rsum > rmax ? rsum : rmax;
			gmax = gsum > gmax ? gsum : gmax;
			bmax = bsum > bmax ? bsum : bmax; 			

			rsum = gsum = bsum = 0;
		}
	}

	*r = rmax;
	*g = gmax;
	*b = bmax;
}

int gamestr(const game *game, char *dst, size_t dst_len)
{
	const char *dst_end = dst + dst_len;

	int chars_written;
	if ((chars_written = snprintf(dst, dst_len, "Game #%u -", game->id)) < 0)
	{
		perror("could not format game");
		return chars_written;
	}

	dst += chars_written;

	for (game_node *next = game->start; next != NULL; next = next->next)
	{
		char *color_str;
		switch (next->color)
		{
		case RED:
			color_str = "RED";
			break;
		case GREEN:
			color_str = "GREEN";
			break;
		case BLUE:
			color_str = "BLUE";
			break;
		default:
			color_str = "???";
		}

		if (dst >= dst_end)
			return -1;

		char sep = next->end_of_segment ? ';' : ',';

		if ((chars_written = snprintf(dst, dst_len, " %ux %s%c", next->count, color_str, sep)) < 0)
		{
			perror("could not format game");
			return chars_written;
		}

		dst += chars_written;
	}

	*(dst - 1) = '\0';

	return 0;
}

int game_cleanup(const game *game)
{
	if (game == NULL)
		return -1;

	game_node *node = game->start;
	while (node != NULL)
	{
		game_node *tmp = node->next;
		free(node);
		node = tmp;
	}

	return 0;
}