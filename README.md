# What is it?
This whole project is my attempt to learn [zig](https://ziglang.org/) and understand it's weak and strong sides.
Link to puzzle list [adventofcode.com](https://adventofcode.com/2022).

# About solutions
1. Use priority queue for 3 elements to avoid whole list sort.
2. Calculate scores by the description from puzzle. Zig gives ability to generate switch cases in compile time.
3. Find common rucksacks element by two static bit sets.
4. Just detect overlaps in linear segments.
5. Use array of stacks and temporary stack to simulate crate movings. 
6. Sliding window and bit set for marking distinct characters. 
7. Since input is BFS of filesystem we can use stack to collect all dir sizes and find minimal needed among them.
8. Probably there is exist more optimal solution. Use definition from puzzle description for each tree.
9. Simulate rope movement from part one in the same way for each pair of consequent rope nodes from part two. Mark rope last node position after every move.
10. Carefully translate description of CRT from puzzle to code.
11. We can't store worry level directly, but since there is limited number of monkeys and their dividers checks we can use modulo division properties.
12.
13.
14.
15.
16.
17.
18.
19.
20.
21.
22.
