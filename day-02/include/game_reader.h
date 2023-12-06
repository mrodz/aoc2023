#ifndef __GAME_READER_H__
#define __GAME_READER_H__

#ifdef __cplusplus
extern "C"
{
#endif

#ifdef DEBUG_IO
#define _GAME_READER_DEBUG_IO
#endif

#include <stdint.h>
#include <stdio.h>
#include <game.h>

#define PARSER_BLOCK_SIZE 80

	typedef enum _game_reader_result_t
	{
		UNSET,
		OK,
		IO_ERROR,
		MALLOC_ERROR,
		_EOF,
		BUF_TOO_SMALL,
		FMT_ERROR,
	} game_reader_result_t;

	typedef struct _game_reader_settings
	{
		uint8_t verbose;
	} game_reader_settings;

	typedef struct _parser_state
	{
		FILE *fp;
		char *buffer;
		size_t length;
		size_t capacity;
		game_reader_settings *settings;
	} parser_state;

	typedef struct _lines_reader
	{
		parser_state *backing;
		size_t index;
		uint8_t done;
	} lines_reader;

	char *const str_game_reader_result(game_reader_result_t result);

	game_reader_result_t games_from_path(game *dst, size_t len, char *const path, game_reader_settings *o);
	game_reader_result_t game_from_str(game *dst, char *str, size_t buf_c);

	game_reader_result_t io_read_in(FILE **fp, char *const path);

	parser_state parser(FILE *fp, game_reader_settings *o);
	game_reader_result_t parser_alloc_block(parser_state *parser);
	size_t parser_bytes_free(parser_state *parser);
	game_reader_result_t parser_heap_read(parser_state *parser);
	char *parser_get_free_region(parser_state *parser);

	lines_reader lines(parser_state *parser);
	game_reader_result_t lines_next_pos(lines_reader *lines, char **start, char **end);
	game_reader_result_t lines_seek_next(lines_reader *lines, char *buffer, size_t buf_c);

#ifdef __cplusplus
}
#endif

#endif