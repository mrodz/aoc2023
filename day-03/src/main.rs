use std::time::{Instant, Duration};

fn consume_char_slice_for_num(slice: &mut [char]) -> Option<u32> {
    let mut result = 0;
    for (pow, char) in slice.iter().rev().enumerate() {
        result += char.to_digit(10)? * 10_u32.pow(pow.try_into().unwrap());
    }

    slice.fill('\0');

    Some(result)
}

fn top_bottom_numbers(row: &mut [char], col: usize) -> Vec<u32> {
    let mut l = col;

    while let Some(c) = l.checked_sub(1).and_then(|diff| row.get(diff)) {
        if !c.is_ascii_digit() {
            break;
        }

        l -= 1;
    }

    let mut r = 0;

    while let Some(c) = row.get(col + 1 + r) {
        if !c.is_ascii_digit() {
            break;
        }
        r += 1;
    }

    let (l_part, r_part) = row.split_at_mut(col);
    let (middle, r_part) = r_part.split_first_mut().unwrap();

    let l_part = &mut l_part[(l)..];
    let r_part = &mut r_part[..(r)];

    let l_empty = l_part.is_empty();
    let r_empty = r_part.is_empty();

    if middle.is_ascii_digit() {
        let range = match (l_empty, r_empty) {
            (false, false) => l..=col + r,
            (false, true) => l..=col,
            (true, false) => col..=col + r,
            (true, true) => col..=col,
        };

        vec![consume_char_slice_for_num(row.get_mut(range).unwrap()).unwrap()]
    } else {
        let mut result = vec![];

        if !l_empty {
            result.push(consume_char_slice_for_num(l_part).unwrap());
        }

        if !r_empty {
            result.push(consume_char_slice_for_num(r_part).unwrap());
        }

        result
    }
}

fn top_numbers(grid: &mut [Vec<char>], row: usize, col: usize) -> Vec<u32> {
    let Some(index) = row.checked_sub(1) else {
        return vec![];
    };
    if let Some(row_above) = grid.get_mut(index) {
        top_bottom_numbers(row_above, col)
    } else {
        vec![]
    }
}

fn bottom_numbers(grid: &mut [Vec<char>], row: usize, col: usize) -> Vec<u32> {
    if let Some(row_below) = grid.get_mut(row + 1) {
        top_bottom_numbers(row_below, col)
    } else {
        vec![]
    }
}

fn left_right(grid: &mut [Vec<char>], row: usize, col: usize) -> Vec<u32> {
    let this_row = grid.get_mut(row).unwrap();

    let mut leftmost_bound = col;

    while let Some(i) = leftmost_bound.checked_sub(1) {
        if !this_row.get(i).is_some_and(char::is_ascii_digit) {
            break;
        }
        leftmost_bound -= 1;
    }

    let mut rightmost_bound = 0;

    while this_row
        .get(col + rightmost_bound + 1)
        .is_some_and(char::is_ascii_digit)
    {
        rightmost_bound += 1;
    }

    let (left_slice, right_slice) = this_row.split_at_mut(col);
    let (_, right_slice) = right_slice.split_first_mut().unwrap();

    let left_slice = &mut left_slice[leftmost_bound..];
    let right_slice = &mut right_slice[..rightmost_bound];

    let mut result = vec![];

    if !left_slice.is_empty() {
        result.push(consume_char_slice_for_num(left_slice).unwrap());
    }

    if !right_slice.is_empty() {
        result.push(consume_char_slice_for_num(right_slice).unwrap());
    }

    result
}

fn vec_from_str(input: &str) -> Vec<Vec<char>> {
    let mut grid: Vec<Vec<char>> = Vec::new();

    for line in input.lines() {
        grid.push(line.chars().collect());
    }

    grid
}

fn part_one(grid: &mut Vec<Vec<char>>) -> (u32, Duration) {
    let start = Instant::now();
    let mut sum = 0;

    for i in 0..grid.len() {
        let len = grid[i].len();

        for j in 0..len {
            let c = grid[i][j];

            if !c.is_ascii_digit() && c != '.' && c != '\0' {
                let mut top = top_numbers(grid, i, j);
                let mut bottom = bottom_numbers(grid, i, j);
                let mut left_right = left_right(grid, i, j);

                top.append(&mut bottom);
                top.append(&mut left_right);

                let all = top;

                sum += all.iter().fold(0, std::ops::Add::add);
            }
        }
    }

    (sum, Instant::now() - start)
}

fn part_two(grid: &mut Vec<Vec<char>>) -> (u32, Duration) {
    let start = Instant::now();

    let mut sum = 0;

    for i in 0..grid.len() {
        let len = grid[i].len();

        for j in 0..len {
            let c = grid[i][j];

            if c == '*' {
                let mut top = top_numbers(grid, i, j);
                let mut bottom = bottom_numbers(grid, i, j);
                let mut left_right = left_right(grid, i, j);

                top.append(&mut bottom);
                top.append(&mut left_right);

                let all = top;

                if all.len() != 2 {
                    continue;
                }

                sum += all[0] * all[1];
            }
        }
    }
    (sum, Instant::now() - start)
}

fn main() {
    let content = include_str!("../input/input.txt");

    let mut grid = vec_from_str(content);

    let (p1, dur) = part_one(&mut grid.clone());

    println!("sum = {p1} (took {} microseconds)", dur.as_micros());

    let (p2, dur) = part_two(&mut grid);

    println!("gear ratio sum = {p2} (took {} microseconds)", dur.as_micros());

}
