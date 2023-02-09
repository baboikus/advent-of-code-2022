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
12. BFS from start 'a' to finish 'E' and from 'E' to any 'a'.
13. Functional style in zig kind of verbose. Instead of using two stacks we are fully parsing lists to "recursive" structures and traverse two of this simultaneously.
14. Another puzzle solved by simply translated falling rules to code.
15. This one could be solved more elegant and effective but brute force approach works for me.
16. Finally some good old dynamic programming. The second part solved by using property of your and elephant's state symmetry. We can swap position of elephant and you any turn.
17. First part solution is minimal tetris game. Second part solved by finding cycles in the game states due to deterministic nature of whole game process.
18. 3D BFS! Oh boy!
19. Some dynamic programming again. We are using branch and bound approach to reduce memotable size. And it's better to not memorize values for last steps.
20. The secret to effective mixing is to reduce the number of steps. Since the list has a cyclic structure, we can only use remainders from division by the length of the list.
21.
22.
23.
24.
25.
