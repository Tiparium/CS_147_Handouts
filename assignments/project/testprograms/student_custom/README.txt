Student Custom Tests
====================

1. Put your custom .asm tests in this directory.
2. Add each test filename to the phase-specific list, one per line:
   - all_phase_1.list
   - all_phase_2.list
   - all_phase_3.list
3. Run tests with:
   ./run test project phase_1 <test_name>

Notes:
- Use the filename without .asm for <test_name>.
- Example:
  If all_phase_1.list contains "my_test.asm", run:
  ./run test project phase_1 my_test
