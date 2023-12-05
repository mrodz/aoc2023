#include <game_reader.h>
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
		o->width_of_newline = 1;

		free_later = 1;
	}

	FILE *file;

	game_reader_result_t err;

	if ((err = io_read_in(&file, path)) != OK)
		goto defer;

	parser_state p = parser(file, o);

	for (size_t i = 0; i < len; i++)
	{
		if ((err = parser_seek_line(&p)) != OK)
			goto defer;

		printf("[%lu] `%s`\n", (long unsigned int)i, p.buffer);
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
			perror(emsg);

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
		printf("alloc <init> (start = %p, len = %lu)\n", parser->buffer, parser->capacity + PARSER_BLOCK_SIZE);

	if ((new_block = realloc(parser->buffer, parser->capacity + PARSER_BLOCK_SIZE)) == NULL)
	{
		perror("Could not allocate memory for parser");
		return MALLOC_ERROR;
	}

	parser->buffer = new_block;
	
	char * c = &parser->buffer[parser->capacity - 1];

	parser->capacity += PARSER_BLOCK_SIZE;

	while (c++ < &parser->buffer[parser->capacity - 1]) {
		*c = 0;
	}

	return OK;
}

size_t parser_bytes_free(parser_state *parser)
{
	return parser->capacity - parser->length;
}

char *get_free_region(parser_state *parser)
{
	return parser->buffer + parser->length;
}

game_reader_result_t parser_seek_line(parser_state *parser)
{
	if (feof(parser->fp))
		return OK;

	memset(parser->buffer, 0, parser->capacity);
	parser->length = 0;

	while (1)
	{
		size_t can_read = parser_bytes_free(parser);
		char *free_region = get_free_region(parser);

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

		if (parser_bytes_free(parser) == 0) {
			game_reader_result_t res;
			if ((res = parser_alloc_block(parser)) != OK) {
				if (parser->settings->verbose)
					fprintf(stderr, "failed to resize buffer");
				return res;
			}
		}

		// size_t can_read = parser_bytes_free(parser);

		// if (can_read != 0)
		// {

		// 	size_t bytes_read;

		// 	char *free_region = get_free_region(parser);

		// 	if ((bytes_read = fread(free_region, sizeof(char), can_read, parser->fp)) == 0)
		// 	{
		// 		if (feof(parser->fp))
		// 		{
		// 			size_t chars_deleted = ltrim_newline(parser);

		// 			if (chars_deleted == 0)
		// 			{

		// 				return OK;
		// 			}
		// 		}

		// 		if (ferror(parser->fp))
		// 		{
		// 			perror("fread_s could not get content");
		// 			return IO_ERROR;
		// 		}
		// 	}

		// 	printf("\tRaw Read: \"%s\"\n", parser->buffer);

		// 	parser->length += bytes_read;

		// 	// int newline = 0;

		// 	if (parser->buffer[parser->length - 1] == '\n')
		// 	{
		// 		break;
		// 	}

		// 	// if (parser->buffer[parser->length - 1] != '\0') {
		// 	// 	parser->buffer[parser->length - 1] = '\0';
		// 	// 	parser->length -= 1;
		// 	// 	fseek(parser->fp, -1, SEEK_CUR);
		// 	// }

		// 	size_t chars_deleted = ltrim_newline(parser);

		// 	parser->length -= chars_deleted;

		// 	printf("\tdel = %lu & last = %c\n", (long unsigned int)chars_deleted, parser->buffer[parser->length - 1]);

		// 	fseek(parser->fp, -(int)chars_deleted, SEEK_CUR);

		// 	if (chars_deleted != 0)
		// 	{
		// 		break;
		// 	} /*else {
		// 	}*/
		// }
		// // printf("\tAlloc!!!!\n");
		// parser_alloc_block(parser);
	}

	return OK;
}

size_t ltrim_newline(parser_state *parser)
{
	size_t i = 0;

	printf("\t\tparser.length = %lu\n", (long unsigned int)parser->length);

	if (parser->length < 1)
		return 0;

	for (i = 0; i < parser->length && parser->buffer[i] != '\n'; i++)
		;

	if (i != 0)
	{
		memset(&parser->buffer[i], 0, parser->length - i);
		printf("\t\ti = %lu\n", (long unsigned int)i);
		return parser->length - i;
	}

	return 0;
}

game_reader_result_t next_game(game *dst, parser_state *parser)
{
	return (game_reader_result_t){0};
}