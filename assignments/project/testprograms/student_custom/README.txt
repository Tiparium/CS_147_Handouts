Student Custom Tests
====================

1. Put your custom .asm tests in this directory.
2. Add each test filename to all.list, one per line.
3. Run tests with:
   ./run test project phase_1 <test_name>

Notes:
- Use the filename without .asm for <test_name>.
- Example:
  If all.list contains "my_test.asm", run:
  ./run test project phase_1 my_test
