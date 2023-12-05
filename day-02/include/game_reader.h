#ifndef __GAME_READER_H__
#define __GAME_READER_H__

#include <stdint.h>
#include <stdio.h>
#include <game.h>

#define PARSER_BLOCK_SIZE 80

typedef enum _game_reader_result_t {
	UNSET,
	OK,
	IO_ERROR,
	MALLOC_ERROR,
	_EOF	
} game_reader_result_t;

typedef struct _parser_state {
	FILE * fp;
	char * buffer;
	size_t length;
	size_t capacity;
} parser_state;

game_reader_result_t games_from_path(game * dst, size_t len, char *const path);
game_reader_result_t io_read_in(FILE ** fp, char *const path);
char *const str_game_reader_result(game_reader_result_t result);	

parser_state parser(FILE * fp);
game_reader_result_t next_game(game * dst, parser_state * parser);
game_reader_result_t parser_alloc_block(parser_state * parser);
size_t parser_bytes_free(parser_state * parser);
game_reader_result_t parser_seek_line(parser_state * parser);
char * get_free_region(parser_state * parser);
size_t ltrim_newline(parser_state * parser);

#endif