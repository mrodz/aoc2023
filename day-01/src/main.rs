#[derive(Default, Debug, Clone)]
struct Trie {
    nodes: Vec<TrieNode>,
}

trait TrieLike {
    fn advance(&self, next: char) -> Option<&TrieNode>;
}

impl Trie {
    fn new() -> Self {
        Self {
            ..Default::default()
        }
    }

    fn new_from_slice<'a>(slice: impl AsRef<[&'a str]>) -> Self {
        let mut x = Self::new();

        for word in slice.as_ref() {
            x.append(word);
        }

        x
    }

    fn append(&mut self, data: &str) {
        let mut chars = data.chars();

        let Some(first) = chars.next() else {
            return;
        };

        let mut root_node = None;

        for node in &mut self.nodes {
            if node.value == first {
                root_node = Some(node);
                break;
            }
        }

        if root_node.is_none() {
            self.nodes.push(TrieNode::new(first));
            root_node = Some(self.nodes.last_mut().unwrap());
        }

        let root_node = root_node.unwrap();

        root_node.append(&mut chars);
    }
}

impl TrieLike for Trie {
    fn advance(&self, next: char) -> Option<&TrieNode> {
        self.nodes.iter().find(|node| node.value == next)
    }
}

#[derive(Default, Debug, Clone)]
struct TrieNode {
    value: char,
    children: Vec<TrieNode>,
    can_terminate: bool,
}

impl TrieNode {
    fn new(value: char) -> Self {
        Self {
            value,
            ..Default::default()
        }
    }

    fn new_from_iter(root: char, data: &mut impl Iterator<Item = char>) -> Self {
        let mut children = vec![];

        let next = data.next();

        if let Some(next) = next {
            children.push(Self::new_from_iter(next, data));
        }

        Self {
            value: root,
            children,
            can_terminate: next.is_none(),
        }
    }

    fn append(&mut self, data: &mut impl Iterator<Item = char>) {
        let Some(utf8) = data.next() else {
            self.can_terminate = true;
            return;
        };

        for node in &mut self.children {
            if node.value == utf8 {
                node.append(data);
                return;
            }
        }

        // node does not exist yet
        self.children.push(Self::new_from_iter(utf8, data));
    }
}

impl TrieLike for TrieNode {
    fn advance(&self, value: char) -> Option<&TrieNode> {
        self.children.iter().find(|child| child.value == value)
    }
}

#[inline]
fn number_from_str(str: &str) -> Option<u32> {
    Some(match str {
        "one" | "eno" => 1,
        "two" | "owt" => 2,
        "three" | "eerht" => 3,
        "four" | "ruof" => 4,
        "five" | "evif" => 5,
        "six" | "xis" => 6,
        "seven" | "neves" => 7,
        "eight" | "thgie" => 8,
        "nine" | "enin" => 9,
        _ => return None,
    })
}

fn begin_digit(trie: &Trie, line: &str, use_rtl: bool) -> Option<u32> {
    let mut node: &dyn TrieLike = trie;

    let mut maybe_match_start = None;

    let mut i = if use_rtl {
        line.len() - 1
    } else {
        0
    };

    while let Some(char) = line.as_bytes().get(i) {
        match node.advance(*char as char) {
            Some(next) if next.can_terminate => {
                let start = maybe_match_start.take().expect("start was not set");

                let str_given = if use_rtl {
                    &line[i..=start]
                } else {
                    &line[start..=i]
                };

                let as_number = number_from_str(str_given).expect(&("NaN: ".to_owned() + str_given));

                return Some(as_number);
            }
            Some(next) => {
                node = next;
                if maybe_match_start.is_none() {
                    maybe_match_start = Some(i);
                }
            }
            None => {
                if char.is_ascii_digit() {
                    return Some((char - b'0') as u32)
                }

                node = trie;

                if let Some(old_start) = maybe_match_start.take() {
                    if use_rtl {
                        i = old_start - 1;
                    } else {
                        i = old_start + 1;
                    }
                    continue;
                }

            }
        }

        if use_rtl {
            i -= 1;
        } else {
            i += 1;
        }
    }

    None
}

#[cfg(test)]
mod test {
    use super::*;

    macro_rules! test_a_b {
        ($name:ident, $input:literal, $a:literal, $b:literal) => {
            #[test]
            fn $name() {
                let first = first_digit($input).expect("no number #1");
                assert_eq!(first, $a, "#1");
                let last = last_digit($input).expect("no number #2");
                assert_eq!(last, $b, "#2");
            }
        };
        (bad first -> $name:ident, $input:literal) => {
            #[test]
            #[should_panic]
            fn $name() {
                let _ = first_digit($input).expect("no number #1");
            }
        };
        (bad last -> $name:ident, $input:literal) => {
            #[test]
            #[should_panic]
            fn $name() {
                let _ = last_digit($input).expect("no number #1");
            }
        }
    }

    test_a_b!(single, "five", 5, 5);
    test_a_b!(single_rev, "five", 5, 5);
    test_a_b!(digit_word, "abc3defoury", 3, 4);
    test_a_b!(word_digit, "one1abc3defou5ry", 1, 5);
    test_a_b!(backwards, "eerhtxyzfive4cevifc", 5, 4);
    test_a_b!(bad first -> bad_one_ltr, "eno");
    test_a_b!(bad last -> bad_one_rtl, "eno");
    test_a_b!(rand_1, "four22", 4, 2);
    test_a_b!(rand_2, "pnineonetwo2", 9, 2);
    test_a_b!(rand_3, "hkvtvvhrsrsevenfourone7kglfnjzztc", 7, 7);
    test_a_b!(rand_4, "zgrpvl3", 3, 3);
    test_a_b!(rand_5, "cc9241nineninesixtwoneggs", 9, 1);
    test_a_b!(rand_6, "5ktgh", 5, 5);
    test_a_b!(rand_7, "9ninefivevnbrrfrfjfivetwo", 9, 2);
    test_a_b!(rand_8, "fzgnjsz2nine9", 2, 9);
    test_a_b!(rand_9, "z39hpppnncfivenbkc", 3, 5);
    test_a_b!(rand_10, "twoeightsix5zmdmcxcfdnrnjjsixmfqpvndkctzdv", 2, 5);
    test_a_b!(rand_11, "drsgdrrgscqmsggrgq1fsqjhtkkrltt", 1, 1);
    test_a_b!(rand_12, "twoeightsix5zmdmcxcfdnrnjjsixmfqpvndkctzdv", 2, 6);
    test_a_b!(rand_13, "8zvbnthreenvplvljj", 8, 3);

    #[test]
    fn sample() {
        let content = include_str!("./sample.txt");

        let mut result = 0;
    
        for line in content.lines() {
            let first = first_digit(line).expect("no number");
            let last = last_digit(line).expect("no number");
    
            result += dbg!(first * 10 + last);
        }

        assert_eq!(result, 281);
    }
}

fn first_digit(line: &str) -> Option<u32> {
    begin_digit(&ltr(), line, false)
}

fn last_digit(line: &str) -> Option<u32> {
    begin_digit(&rtl(), line, true)
}

fn ltr() -> Trie {
    Trie::new_from_slice([
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    ])
}

fn rtl() -> Trie {
    Trie::new_from_slice([
        "eno", "owt", "eerht", "ruof", "evif", "xis", "neves", "thgie", "enin",
    ])
}

fn main() {
    let content = include_str!("./input.txt");

    let mut result = 0;

    for line in content.lines() {
        let first = first_digit(line).expect("no number #1");
        let last = last_digit(line).expect("no number #2");

        result += first * 10 + last;
    }

    println!("{result}");
}
