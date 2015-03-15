module tests.build;

import unit_threaded;
import reggae;


void testIsLeaf() {
    Target("tgt").isLeaf.shouldBeTrue;
    Target("other", "", [Target("foo"), Target("bar")]).isLeaf.shouldBeFalse;
}


void testInOut() {
    //Tests that specifying $in and $out in the command string gets substituted correctly
    {
        const target = Target("foo",
                              "createfoo -o $out $in",
                              [Target("bar.txt"), Target("baz.txt")]);
        target.command.shouldEqual("createfoo -o foo bar.txt baz.txt");
    }
    {
        const target = Target("tgt",
                              "gcc -o $out $in",
                              [
                                  Target("src1.o", "gcc -c -o $out $in", [Target("src1.c")]),
                                  Target("src2.o", "gcc -c -o $out $in", [Target("src2.c")])
                                  ],
            );
        target.command.shouldEqual("gcc -o tgt src1.o src2.o");
    }

    {
        const target = Target(["proto.h", "proto.c"],
                              "protocompile $out -i $in",
                              [Target("proto.idl")]);
        target.command.shouldEqual("protocompile proto.h proto.c -i proto.idl");
    }

    {
        const target = Target("lib1.a",
                              "ar -o$out $in",
                              [Target(["foo1.o", "foo2.o"], "cmd", [Target("tmp")]),
                               Target("bar.o"),
                               Target("baz.o")]);
        target.command.shouldEqual("ar -olib1.a foo1.o foo2.o bar.o baz.o");
    }
}


void testProject() {
    const target = Target("foo",
                          "makefoo -i $in -o $out -p $project",
                          [Target("bar"), Target("baz")]);
    target.command("/tmp").shouldEqual("makefoo -i /tmp/bar /tmp/baz -o foo -p /tmp");
}


void testMultipleOutputs() {
    const target = Target(["foo.hpp", "foo.cpp"], "protocomp $in", [Target("foo.proto")]);
    target.outputs.shouldEqual(["foo.hpp", "foo.cpp"]);
    target.command("myproj").shouldEqual("protocomp myproj/foo.proto");

    const bld = Build(target);
    bld.targets[0].outputs.shouldEqual(["foo.hpp", "foo.cpp"]);
}


void testEnclose() {

    Target("foo.o", "", [Target("foo.c")]).enclose(Target("theapp")).shouldEqual(
            Target("objs/theapp.objs/foo.o", "", [Target("foo.c")]));

    Target("$builddir/bar.o", "", [Target("bar.c")]).enclose(Target("theapp")).shouldEqual(
        Target("bar.o", "", [Target("bar.c")]));

    const leafTarget = Target("foo.c");
    leafTarget.enclose(Target("theapp")).shouldEqual(leafTarget);
}
