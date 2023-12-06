#include <game_reader.h>

#include <game.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *const str_game_reader_result(game_reader_result_t result)
{
	switch (result)
	{
	case UNSET:
		return "unset";
	case OK:
		return "success";
	case IO_ERROR:
		return "I/O error";
	case MALLOC_ERROR:
		return "malloc error";
	case BUF_TOO_SMALL:
		return "specified buffer is too small";
	case FMT_ERROR:
		return "formatting error";
	default:
		return "bad error code";
	}
}

game_reader_result_t games_from_path(game *dst, size_t len, char *const path, game_reader_settings *o)
{
	uint8_t free_later = 0;

	if (o == NULL)
	{
		o = (game_reader_settings *)malloc(sizeof(game_reader_settings));
		o->verbose = 0;
		free_later = 1;
	}

	FILE *file;

	game_reader_result_t err;

	if ((err = io_read_in(&file, path)) != OK)
		goto defer;

	parser_state p = parser(file, o);

	parser_heap_read(&p);

	lines_reader lines_r = lines(&p);

	char LINES_BUFFER[500] = {0};

	for (size_t i = 0; i < len; i++)
	{
		if ((err = lines_seek_next(&lines_r, LINES_BUFFER, sizeof(LINES_BUFFER))) != OK)
		{
			if (err == _EOF)
				break;
			goto defer;
		}

		game *game = dst + i;

		if ((err = game_from_str(game, LINES_BUFFER, sizeof(LINES_BUFFER))) != OK)
		{
			if (err == _EOF)
				break;
			goto defer;
		}

		memset(LINES_BUFFER, 0, sizeof(LINES_BUFFER));
	}

	err = OK;

defer:
	if (free_later)
		free(o);

	if (file != NULL)
	{
		if (fclose(file) != 0)
			perror("Could not close file");
		file = NULL;
	}

	if (err != OK)
		fprintf(stderr, "error %d: %s", err, str_game_reader_result(err));

	return err;
}

game_reader_result_t io_read_in(FILE **fp, char *const path)
{
	*fp = fopen(path, "r");

	if (*fp == NULL)
	{
		int ferr = errno;
		char emsg[1024] = {0};
		if (snprintf(emsg, sizeof(emsg), "Could not open game at \"%s\"", path) == -1)
		{
			perror("Could not format error message");
			fprintf(stderr, "\t^ Original error: %s", strerror(ferr));
		}
		else
		{
			perror(emsg);
		}
		return IO_ERROR;
	}

	return OK;
}

parser_state parser(FILE *fp, game_reader_settings *o)
{
	parser_state result;
	result.buffer = NULL;
	result.fp = fp;
	result.length = 0;
	result.capacity = 0;
	result.settings = o;
	return result;
}

game_reader_result_t parser_alloc_block(parser_state *parser)
{
	char *new_block;

	if (parser->settings->verbose)
		printf("alloc <init> (start = %p, len = %lu)\n", parser->buffer, (long unsigned int)(parser->capacity + PARSER_BLOCK_SIZE));

	if ((new_block = realloc(parser->buffer, parser->capacity + PARSER_BLOCK_SIZE)) == NULL)
	{
		perror("Could not allocate memory for parser");
		return MALLOC_ERROR;
	}

	parser->buffer = new_block;

	char *c = &parser->buffer[parser->capacity - 1];

	parser->capacity += PARSER_BLOCK_SIZE;

	while (c++ < &parser->buffer[parser->capacity - 1])
		*c = 0;

	return OK;
}

size_t parser_bytes_free(parser_state *parser)
{
	return parser->capacity - parser->length;
}

char *parser_get_free_region(parser_state *parser)
{
	return parser->buffer + parser->length;
}

game_reader_result_t parser_heap_read(parser_state *parser)
{
	if (feof(parser->fp))
		return OK;

	memset(parser->buffer, 0, parser->capacity);
	parser->length = 0;

	while (1)
	{
		size_t can_read = parser_bytes_free(parser);
		char *free_region = parser_get_free_region(parser);

		size_t bytes_read;

		if ((bytes_read = fread(free_region, sizeof(char), can_read, parser->fp)) == 0)
		{
			if (ferror(parser->fp))
			{
				perror("fread could not get content");
				return IO_ERROR;
			}

			if (feof(parser->fp))
				break;
		}

		if (parser->settings->verbose)
			printf("\tBuffer is: \"%s\"\n", parser->buffer);

		parser->length += bytes_read;

		if (parser_bytes_free(parser) == 0)
		{
			game_reader_result_t res;
			if ((res = parser_alloc_block(parser)) != OK)
			{
				if (parser->settings->verbose)
					fprintf(stderr, "failed to resize buffer");
				return res;
			}
		}
	}

	return OK;
}

#define GREEDY_CONSUME_UNTIL(char) while (str < end_exclusive && (*(str++) != char))
#define CHECK_BOUNDS(message)          \
	if (str >= end_exclusive - 1)      \
	{                                  \
		fprintf(stderr, message "\n"); \
		return BUF_TOO_SMALL;          \
	}

game_reader_result_t game_from_str(game *dst, char *str, size_t buf_c)
{
	if (*str == '\0')
		return _EOF;

	const char *end_exclusive = str + buf_c;

	if (buf_c < 6)
	{
		fprintf(stderr, "Cannot begin parsing str, input buffer too small\n");
		return BUF_TOO_SMALL;
	}

	if (strncmp("Game ", str, 5) != 0)
	{
		fprintf(stderr, "Bad start, expected `Game `: parsing starts here: `%s`\n", str);
		return FMT_ERROR;
	}

	str += 5;

	size_t game_id = atoi(str);

	if (game_id == 0)
	{
		fprintf(stderr, "Bad int (id): parsing starts here: `%s`\n", str);
		return FMT_ERROR;
	}

	dst->id = game_id;

	GREEDY_CONSUME_UNTIL(':');
	CHECK_BOUNDS("failed at ':'");

	game_node **node = &dst->start;
	game_node **prev = NULL;

	while (str < end_exclusive)
	{
		// printf("\t&^ %s (%c %d)\n", str, *str, *str);

		if (*str == '\0')
		{
			break;
		}
		if (*str == ' ')
		{
			str++;
			continue;
		}

		uint32_t value = atoi(str);

		if (value == 0)
		{
			fprintf(stderr, "Bad int: parsing starts here (%p < %p): `%s`\n", str, end_exclusive, str);
			return FMT_ERROR;
		}

		GREEDY_CONSUME_UNTIL(' ');
		CHECK_BOUNDS("failed after number");

		game_color color;

		if (strncmp("red", str, 3) == 0)
		{
			color = RED;
			str += 3;
		}
		else if (strncmp("green", str, 5) == 0)
		{
			color = GREEN;
			str += 5;
		}
		else if (strncmp("blue", str, 4) == 0)
		{
			color = BLUE;
			str += 4;
		}
		else
		{
			fprintf(stderr, "Bad color: parsing starts here: `%s`\n", str);
			return FMT_ERROR;
		}

		CHECK_BOUNDS("failed after color");

		*node = (game_node *)calloc(1, sizeof(game_node));

		(*node)->count = value;
		(*node)->color = color;

		if (*str == ';')
			(*node)->end_of_segment = 1;

		prev = node;
		node = &(*node)->next;

		str += 2;

		if (str >= end_exclusive)
			break;
	}

	if (prev != NULL)
		(*prev)->end_of_segment = 1;

	return OK;
}

lines_reader lines(parser_state *parser)
{
	lines_reader result;
	result.backing = parser;
	result.done = 0;
	result.index = 0;
	return result;
}

game_reader_result_t lines_next_pos(lines_reader *lines, char **start, char **end)
{
	size_t i_start = lines->index;
	*start = &lines->backing->buffer[i_start];

	size_t *newline_index = &lines->index;

	while (*newline_index < lines->backing->length)
	{
		if (lines->backing->buffer[*newline_index] == '\n')
		{
			*end = &lines->backing->buffer[(*newline_index)++];
			return OK;
		}
		(*newline_index)++;
	}

	if (lines->backing->settings->verbose)
	{
		printf("No newline found in remainder of string (%lu)\n", (long unsigned int)(*newline_index));
	}

	*end = &lines->backing->buffer[lines->backing->length];
	return _EOF;
}

game_reader_result_t lines_seek_next(lines_reader *lines, char *buffer, size_t buf_c)
{
	char *start;
	char *end;

	lines_next_pos(lines, &start, &end);

	if (lines->backing->settings->verbose)
	{
		printf("lines_next_pos() returned: (%p, %p)\n", start, end);
	}

	for (size_t i = 0; start < end; i++)
	{
		if (i >= buf_c)
		{
			fprintf(stderr, "Buffer too small to store line (you gave length: %lu)\n", (long unsigned int)buf_c);
			return BUF_TOO_SMALL;
		}

		buffer[i] = *(start++);
	}

	return OK;
}