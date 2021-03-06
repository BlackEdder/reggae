Feature: Augmenting dub projects with reggae builds
  As a user of both dub and reggae
  I want to base my reggae builds from the dub information
  So I don't have to duplicate work

  Background:
    Given a file named "dub_reggae_proj/dub.json" with:
      """
      {
        "name": "dub_reggae",
        "targetType": "executable",
        "dependencies": {"cerealed": ">=0.5.2"}
      }

      """

    And a file named "dub_reggae_proj/source/util/maths.d" with:
      """
      module util.maths;
      int adder(int i, int j) {
          return i + j;
      }

      int muler(int i, int j) {
          return i * j;
      }
      """

    And a file named "dub_reggae_proj/source/main.d" with:
      """
      import util.maths;
      import cerealed;
      import std.stdio;
      import std.conv;
      void main(string[] args) {
          immutable i = args[1].to!int;
          immutable j = args[2].to!int;
          writeln(`Sum:  `, adder(i, j));
          writeln(`Prod: `, muler(i, j));
          auto enc = Cerealiser();
          enc ~= cast(ubyte)adder(i, j);
          writeln(enc.bytes);
      }
      """

    And a file named "dub_reggae_proj/tests/util/ut_maths.d" with:
      """
      module tests.util.ut_maths;
      import util.maths;
      void testAdd() {
          assert(adder(3, 0) == 3);
          assert(adder(3, 2) == 5);
      }

      void testMul() {
          assert(muler(3, 0) == 0);
          assert(muler(3, 1) == 3);
          assert(muler(3, 4) == 12);
      }
      """

    And a file named "dub_reggae_proj/tests/util/more_maths.d" with:
      """
      module tests.util.more_maths;
      import util.maths;
      unittest {
          assert(adder(3, 4) == 42); //oops
      }
      void testMoreAdder() {
          assert(adder(4, 9) == 13);
      }
      """

    And a file named "dub_reggae_proj/tests/ut.d" with:
      """
      import tests.util.ut_maths;
      import tests.util.more_maths;
      void main() {
          testAdd();
          testMul();
          testMoreAdder();
      }
      """

    And a file named "dub_reggae_proj/reggaefile.d" with:
      """
      import reggae;
      alias utObjs = objectFiles!(Sources!([`tests`]), Flags(`-unittest`), ImportPaths([`source`]));
      alias ut = dubConfigurationTarget!(ExeName(`ut`), Configuration(`default`), Flags(), No.main, utObjs);
      mixin build!(dubDefaultTarget!(), ut);
      """

    @ninja
    Scenario: Dub/Reggae build with Ninja
      Given I successfully run `reggae -b ninja dub_reggae_proj`
      When I successfully run `ninja`
      Then the output should not contain:
        """
        warning: multiple rules generate
        """
      When I run `./ut`
      Then it should fail with:
        """
        unittest failure
        """
      When I successfully run `./dub_reggae 2 3`
      Then the output should contain:
        """
        Sum:  5
        Prod: 6
        [5]
        """

    @make
    Scenario: Dub/Reggae build with Make
      Given I successfully run `reggae -b make dub_reggae_proj`
      When I successfully run `make -j8`
      Then the output should not contain:
        """
        warning: ignoring old recipe for target
        """
      When I run `./ut`
      Then it should fail with:
        """
        unittest failure
        """
      When I successfully run `./dub_reggae 3 4`
      Then the output should contain:
        """
        Sum:  7
        Prod: 12
        [7]
        """

    @binary
    Scenario: Dub/Reggae build with Binary
      Given I successfully run `reggae -b binary dub_reggae_proj`
      When I successfully run `./build`
      Then the output should not contain:
        """
        warning: ignoring old recipe for target
        """
      When I run `./ut`
      Then it should fail with:
        """
        unittest failure
        """
      When I successfully run `./dub_reggae 3 4`
      Then the output should contain:
        """
        Sum:  7
        Prod: 12
        [7]
        """

    @tup
    Scenario: Dub/Reggae build with Tup
      When I run `reggae -b tup dub_reggae_proj`
      Then it should fail with:
        """
        dub integration not supported with the tup backend
        """
