require_relative 'internal/curried_method'
require_relative 'internal/functors'

module Ramda
  # Math functions
  # rubocop:disable Metrics/ModuleLength
  module Object
    extend ::Ramda::Internal::CurriedMethod

    Functors = ::Ramda::Internals::Functors

    # Makes a shallow clone of an object, setting or overriding the specified
    # property with the given value. Note that this copies and flattens
    # prototype properties onto the new object as well. All non-primitive
    # properties are copied by reference.
    #
    # String -> a -> {k: v} -> {k: v}
    #
    curried_method(:assoc) do |key, val, obj|
      obj.merge(key => val)
    end

    # Makes a shallow clone of an object, setting or overriding the nodes
    # required to create the given path, and placing the specific value at
    # the tail end of that path. Note that this copies and flattens
    # prototype properties onto the new object as well. All non-primitive
    # properties are copied by reference.
    #
    # [Idx] -> a -> {a} -> {a}
    # Idx = String | Int
    #
    curried_method(:assoc_path) do |path, val, obj|
      if path.empty?
        val
      else
        cloned = clone(obj)
        path[0...-1].reduce(cloned) do |acc, k|
          case acc[k]
          when Hash, Array
            acc[k]
          else
            acc[k] = k.is_a?(Integer) ? [] : {}
          end
        end[path[-1]] = val
        cloned
      end
    end

    # Creates a deep copy of the value which may contain (nested)
    # Arrays and Objects, Numbers, Strings, Booleans and Dates.
    # Functions are assigned by reference rather than copied
    #
    # {*} -> {*}
    #
    curried_method(:clone) do |obj|
      case obj
      when Hash
        obj.each_with_object(obj.dup) do |(key, value), acc|
          acc[clone(key)] = clone(value)
        end
      when Array
        obj.map(&clone)
      when Symbol, Integer, NilClass, TrueClass, FalseClass
        obj
      else
        obj.dup
      end
    end

    # Returns a new object that does not contain a prop property.
    #
    # String -> {k: v} -> {k: v}
    #
    curried_method(:dissoc) do |prop, obj|
      clone(obj).tap { |o| o.delete(prop) }
    end

    # Returns whether or not an object has an own property with the specified name
    #
    # s -> {s: x} -> Boolean
    #
    curried_method(:has) do |key, obj|
      obj.key?(key)
    end

    # Returns whether or not an object or its prototype chain has a property
    # with the specified name
    #
    # s -> {s: x} -> Boolean
    #
    curried_method(:has_in) do |key, obj|
      obj.respond_to?(key)
    end

    # Reports whether two objects have the same value, in R.equals terms,
    # for the specified property. Useful as a curried predicate.
    #
    # k -> {k: v} -> {k: v} -> Boolean
    #
    curried_method(:eq_props) do |prop, a, b|
      a[prop] == b[prop]
    end

    # Returns a list containing the names of all the enumerable own properties
    # of the supplied object.
    # Note that the order of the output array is not guaranteed.
    #
    # {k: v} -> [k]
    #
    curried_method(:keys, &:keys)

    # Returns a list containing the names of all the properties of the supplied
    # object, including prototype properties.
    #
    # {k: v} -> [k]
    #
    curried_method(:keys_in) do |obj|
      (obj.methods - obj.class.methods)
        .map(&:to_s)
        .reject { |r| r.include?('=') }
        .map(&:to_sym)
        .uniq
    end

    # Returns a lens for the given getter and setter functions.
    # The getter "gets" the value of the focus;
    # the setter "sets" the value of the focus.
    # The setter should not mutate the data structure.
    #
    # (s -> a) -> ((a, s) -> s) -> Lens s a
    # Lens s a = Functor f => (a -> f a) -> s -> f s
    #
    curried_method(:lens) do |getter, setter|
      curried_method_body(:lens, 2) do |to_functor_fn, target|
        Ramda.map(
          ->(focus) { setter.call(focus, target) },
          to_functor_fn.call(getter.call(target))
        )
      end
    end

    # Returns a lens whose focus is the specified index.
    #
    # Number -> Lens s a
    # Lens s a = Functor f => (a -> f a) -> s -> f s
    #
    curried_method(:lens_index) do |n|
      lens(Ramda.nth(0), Ramda.update(n))
    end

    # Returns a lens whose focus is the specified path.
    #
    # [Idx] -> Lens s a
    # Idx = String | Int
    # Lens s a = Functor f => (a -> f a) -> s -> f s
    #
    curried_method(:lens_path) do |path|
      lens(Ramda.path(path), Ramda.assoc_path(path))
    end

    # Returns a lens whose focus is the specified property.
    #
    # String -> Lens s a
    # Lens s a = Functor f => (a -> f a) -> s -> f s
    #
    curried_method(:lens_prop) do |k|
      lens(Ramda.prop(k), Ramda.assoc(k))
    end

    # Create a new object with the own properties of the first object merged
    # with the own properties of the second object. If a key exists in both
    # objects, the value from the second object will be used.
    #
    # {k: v} -> {k: v} -> {k: v}
    #
    curried_method(:merge) do |obj_a, obj_b|
      obj_a.merge(obj_b)
    end

    # Returns a partial copy of an object omitting the keys specified.
    #
    # [String] -> {String: *} -> {String: *}
    #
    curried_method(:omit) do |keys, obj|
      obj_copy = clone(obj)
      keys.each(&obj_copy.method(:delete))
      obj_copy
    end

    # Returns the result of "setting" the portion of the given data
    # structure focused by the given lens to the result of applying
    # the given function to the focused value.
    #
    # Lens s a -> (a -> a) -> s -> s
    # Lens s a = Functor f => (a -> f a) -> s -> f s
    #
    curried_method(:over) do |lens, f, x|
      # The value returned by the getter function is first transformed with `f`,
      # then set as the value of an `Identity`. This is then mapped over with the
      # setter function of the lens.
      lens
        .call(->(y) { Functors::Identity.of(y).map(f) }, x)
        .value
    end

    # Retrieve the value at a given path.
    #
    # [Idx] -> {a} -> a | NilClass
    # Idx = String | Int
    #
    curried_method(:path) do |keys, obj|
      keys.reduce(obj) { |acc, key| acc.respond_to?(:fetch) ? acc[key] : nil }
    end

    # Returns a partial copy of an object containing only the keys specified.
    # If the key does not exist, the property is ignored.
    #
    # [k] -> {k: v} -> {k: v}
    #
    curried_method(:pick) do |keys, obj|
      obj.select { |k, _| keys.include?(k) }
    end

    # Similar to pick except that this one includes a key: undefined pair for
    # properties that don't exist.
    #
    # [k] -> {k: v} -> {k: v}
    #
    curried_method(:pick_all) do |keys, obj|
      Hash[keys.map { |k| [k, obj.key?(k) ? obj.fetch(k) : nil] }]
    end

    # Returns a partial copy of an object containing only the keys that
    # satisfy the supplied predicate.
    #
    # (v, k -> Boolean) -> {k: v} -> {k: v}
    #
    curried_method(:pick_by) do |fn, obj|
      obj.select { |k, v| fn.call(v, k) }
    end

    # Reasonable analog to SQL select statement.
    #
    # [k] -> [{k: v}] -> [{k: v}]
    #
    curried_method(:project) do |keys, objs|
      objs.map(&pick_all(keys))
    end

    # Returns a function that when supplied an object returns the indicated
    # property of that object, if it exists.
    #
    # s -> {s: a} -> a | NilClass
    #
    curried_method(:prop) do |key, obj|
      obj[key]
    end

    # If the given, non-null object has an own property with the specified
    # name, returns the value of that property. Otherwise returns
    # the provided default value.
    #
    # a -> String -> Object -> a
    #
    curried_method(:prop_or) do |val, name, obj|
      case obj
      when Hash
        obj[name] || val
      else
        obj.respond_to?(name) || val
      end
    end

    # Acts as multiple prop: array of keys in, array of values out.
    # Preserves order.
    #
    # [k] -> {k: v} -> [v]
    #
    curried_method(:props) do |keys, obj|
      keys.map(&obj.method(:[]))
    end

    # Returns the result of "setting" the portion of the given data structure
    # focused by the given lens to the given value.
    #
    # Lens s a -> a -> s -> s
    # Lens s a = Functor f => (a -> f a) -> s -> f s
    #
    curried_method(:set) do |lens, v, x|
      over(lens, Ramda.always(v), x)
    end

    # Converts an object into an array of key, value arrays. Only the
    # object's own properties are used. Note that the order of the
    # output array is not guaranteed.
    #
    # {String: *} -> [[String,*]]
    #
    curried_method(:to_pairs, &:to_a)

    # Returns a list of all the enumerable own properties of the supplied object.
    #
    # {k: v} -> [v]
    #
    curried_method(:values, &:values)

    # Returns a list of all the properties, including prototype properties,
    # of the supplied object.
    #
    # {k: v} -> [v]
    #
    curried_method(:values_in) do |obj|
      keys_in(obj).map(&obj.method(:send))
    end

    # Returns a "view" of the given data structure, determined
    # by the given lens. The lens's focus determines which portion
    # of the data structure is visible.
    #
    # Lens s a -> s -> a
    # Lens s a = Functor f => (a -> f a) -> s -> f s
    #
    curried_method(:view) do |lens, x|
      # Using `const` effectively ignores the setter function of the `lens`,
      # leaving the value returned by the getter function unmodified.
      lens
        .call(Functors::Const.method(:of), x)
        .value
    end

    # Takes a spec object and a test object; returns true if the test satisfies
    # the spec. Each of the spec's own properties must be a predicate function.
    # Each predicate is applied to the value of the corresponding property of
    # the test object. where returns true if all the predicates return true,
    # false otherwise.
    #
    # where is well suited to declaratively expressing constraints for other
    # functions such as filter and find.
    #
    # {String: (* -> Boolean)} -> {String: *} -> Boolean
    #
    curried_method(:where) do |spec, test|
      spec.all? { |k, v| v.call(test[k]) }
    end
  end
end
