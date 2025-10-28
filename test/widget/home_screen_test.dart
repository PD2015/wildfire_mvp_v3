
testWidgets('CI/CD test - intentional failure', (tester) async {
  expect(true, isFalse, reason: 'Intentional failure to test CI blocking');
});
