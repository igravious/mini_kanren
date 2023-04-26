require "rspec"
require 'mini_kanren'
require 'mini_kanren/core'

describe "Core" do
  it "all()" do
    MiniKanren.exec do
      q = fresh
      run(q,eq(true, q)).should == [true]
      run(q, failure).should == []
      run(q, eq(true, q)).should == [true]
      run(q, all(failure, eq(true, q))).should == []
      run(q, all(success, eq(true, q))).should == [true]
      run(q, all(success, eq(:corn, q))).should == [:corn]
      run(q, all(failure, eq(:corn, q))).should == []
      run(q, all(success, eq(false, q))).should == [false]

      x = fresh
      run(q, eq(true,q))
      run(q, all(eq(true, x), eq(true, q))).should == [true]
      run(q, all(eq(x, true), eq(true, q))).should == [true]
      run(q, success).should == ["_.0"]
      run(q, success).should == ["_.0"]

      x, y = fresh(2)
      run(q, eq([x, y], q)).should == [["_.0", "_.1"]]
      t, u = fresh(2)
      run(q, eq([t, u], q)).should == [["_.0", "_.1"]]

      x = fresh
      y = x
      x = fresh
      run(q, eq([y, x, y], q)).should == [["_.0", "_.1", "_.0"]]

      run(q, all(eq(false, q), eq(true, q))).should == []
      run(q, all(eq(false, q), eq(false, q))).should == [false]

      x = q
      run(q, eq(true, x)).should == [true]

      x = fresh
      run(q, eq(x, q)).should == ["_.0"]
      run(q, all(eq(true, x), eq(x, q))).should == [true]
      run(q, all(eq(x, q), eq(true, x))).should == [true]
    end
  end

  it "conde()" do
    MiniKanren.exec do
      q, x = fresh(2)

      run(q, eq(x == q, q)).should == [false]

      run(q, conde(all(failure, success),
      all(success, failure))).should == []

      run(q, conde(all(failure, failure),
      all(success, success))).should == ["_.0"]

      run(q, conde(all(success, success),
      all(failure, failure))).should == ["_.0"]

      run(q, conde(all(eq(:olive, q), success),
      all(eq(:oil, q), success))).should == [:olive, :oil]

      run(1, q, conde(all(eq(:olive, q), success),
      all(eq(:oil, q), success))).should == [:olive]

      run(q, conde(all(eq(:virgin, q), failure),
      all(eq(:olive, q), success),
      all(success, success),
      all(eq(:oil, q), success))).should == [:olive, "_.0", :oil]

      run(q, conde(all(eq(:olive, q), success),
      all(success, success),
      all(eq(:oil, q), success))).should == [:olive, "_.0", :oil]

      run(2, q, conde(all(eq(:extra, q), success),
      all(eq(:virgin, q), failure),
      all(eq(:olive, q), success),
      all(eq(:oil, q), success))).should == [:extra, :olive]

      x = fresh
      y = fresh
      run(q, conde(all(eq(:split, x),
      eq(:pea, y),
      eq([x, y], q)))).should == [[:split, :pea]]

      run(q, all(
      conde(
      all(eq(:split, x), eq(:pea, y)),
      all(eq(:navy, x), eq(:bean, y)))),
      eq([x, y], q)).should == [[:split, :pea], [:navy, :bean]]

      run(q, all(
      conde(
      all(eq(:split, x), eq(:pea, y)),
      all(eq(:navy, x), eq(:bean, y))),
      eq([x, y, :soup], q))).should == [[:split, :pea, :soup],
      [:navy, :bean, :soup]]

      def teacupo(x)
        conde(
        all(eq(:tea, x), success),
        all(eq(:cup, x), success))
      end

      run(q, teacupo(q)).should == [:tea, :cup]

      run(q, all(
      conde(
      all(teacupo(x), eq(true, y), success),
      all(eq(false, x), eq(true, y))),
      eq([x, y], q))).should ==
      [[false, true], [:tea, true], [:cup, true]]

      x, y, z = fresh(3)
      x_ = fresh
      run(q, all(
      conde(
      all(eq(y, x), eq(z, x_)),
      all(eq(y, x_), eq(z, x))),
      eq([y, z], q))).should ==
      [["_.0", "_.1"], ["_.0", "_.1"]]

      run(q, all(
      conde(
      all(eq(y, x), eq(z, x_)),
      all(eq(y, x_), eq(z, x))),
      eq(false, x),
      eq([y, z], q))).should ==
      [[false, "_.0"], ["_.0", false]]

      a = eq(true, q)
      b = eq(false, q)
      run(q, b).should == [false]

      x = fresh
      b = all(
      eq(x, q),
      eq(false, x))
      run(q, b).should == [false]

      x, y = fresh(2)
      run(q, eq([x, y], q)).should == [["_.0", "_.1"]]

      v, w = fresh(2)
      x, y = v, w
      run(q, eq([x, y], q)).should == [["_.0", "_.1"]]

    end
  end

  it "project()" do
    MiniKanren.exec do
      q, x = fresh(2)

      run(q, all(eq(x,5), project(x, lambda { |x| eq(q, x + x) }))).should == [10]
      run(q, all(eq(x,"Hello"), project(x, lambda { |x| eq(q, x + x) }))).should == ["HelloHello"]

      s = {one: 1, two: fresh}
      q = fresh
      run(q, eq(q, s), project(s, lambda { |s| eq(s,s) })).should == [{one: 1, two: "_.0"}]

      bar = {notes: [{note: fresh}, {note: fresh}]}
      q = fresh
      run(q,
      eq(q, bar),
      eq(bar[:notes][0][:note], 1),
      eq(bar[:notes][1][:note], 1),
      project(bar, lambda { |x| eq(x[:notes][0][:note] + x[:notes][1][:note], 2) })).should == [{notes: [{note: 1}, {note: 1}]}]

      option, q = fresh(2)
      run(q, eq(q, option), conde(eq(option, 0), eq(option, 1)), project(option, lambda { |option| eq(option + 1, 1) })).should == [0]
    end
  end

  it "hash" do
    MiniKanren.exec do
      h1 = {}
      h2 = {}
      q = fresh
      run(q, eq(h1, h2)).should == ["_.0"]

      h1 = {hi: 1}
      h2 = {hi: 1}
      q = fresh
      run(q, eq(h1, h2)).should == ["_.0"]

      x = fresh
      h1 = {hi: 1, you: x}
      h2 = {hi: 1, you: x}
      q = fresh
      run(q, eq(h1, h2)).should == ["_.0"]

      h1 = {hi: 1, you: fresh}
      h2 = {hi: 1, you: fresh}
      q = fresh
      run(q, eq(h1, h2)).should == ["_.0"]

      x,y = fresh(2)
      h1 = {hi: 1, you: x}
      h2 = {hi: 1, you: y}
      q = fresh
      run(q, eq(h1, h2)).should == ["_.0"]

      x,y = fresh(2)
      h1 = {hi: 1, you: x}
      h2 = {hi: 1, you: y}
      q = fresh
      run(q, eq(h1, h2), eq(x, 2)).should == ["_.0"]

      x,y = fresh(2)
      h1 = {hi: 1, you: x}
      h2 = {hi: 1, you: y}
      q = fresh
      run(q, eq(q, h1), eq(h1, h2), eq(x, 2)).should == [{hi: 1, you: 2}]

      h1 = {hi: 1, you: fresh}
      h2 = {hi: 1, you: fresh}
      q = fresh
      run(q, eq(q, h1), eq(h1, h2), eq(h1[:you], 3)).should == [{hi: 1, you: 3}]

      h1 = {hi: 1, you: [fresh, "peas"]}
      h2 = {hi: 1, you: ["sweetcorn", fresh]}
      q = fresh
      run(q, eq(q, h1), eq(h1, h2)).should == [{hi: 1, you: ["sweetcorn", "peas"]}]

      h1 = {hi: 1, you: {fruit: fresh, veg: "peas"}}
      h2 = {hi: 1, you: {fruit: "apple", veg: fresh}}
      q = fresh
      run(q, eq(q, h1), eq(h1, h2)).should == [{hi: 1, you: {fruit: "apple", veg: "peas"}}]

      h1 = {hi: 1, you: fresh}
      h2 = {hi: 1, you: {fruit: "apple", veg: fresh}}
      q = fresh
      run(q, eq(q, h1), eq(h1, h2)).should == [{hi: 1, you: {fruit: "apple", veg: "_.0"}}]

    end
  end

  it "extensions" do
    MiniKanren.exec do
      q = fresh

      def nullo(l)
        eq(l, [])
      end

      def conso(a, d, p)
        eq([a, d], p)
      end

      def pairo(p)
        a, d = fresh(2)
        conso(a, d, p)
      end

      def cdro(p, d)
        a = fresh
        conso(a, d, p)
      end

      def caro(p, a)
        d = fresh
        conso(a, d, p)
      end

      run(q, all(pairo([q, q]), eq(true, q))).should == [true]
      run(q, all(pairo([]), eq(true, q))).should == []

      def listo(l)
        d = fresh
        conde(
        all(nullo(l), success),
        all(pairo(l), cdro(l, d), defer(method(:listo), d)))
      end

      run(q, listo([:a, [:b, [q, [:d, []]]]])).should == ["_.0"]

      run(5, q, listo([:a, [:b, [:c, q]]])).should ==
      [[],
      ["_.0", []],
      ["_.0", ["_.1", []]],
      ["_.0", ["_.1", ["_.2", []]]],
      ["_.0", ["_.1", ["_.2", ["_.3", []]]]]]

      fresh { |q|
        run(q, fresh { |q| eq(q, false) }).should == ["_.0"]
      }
    end
  end
end
