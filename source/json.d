module json;

public import std.json;
import std.traits : isFloatingPoint, isIntegral, isSomeString, isArray, isNumeric;
import std.range.primitives : ElementType;

struct Ignore
{

}

JSONValue toJson(T)(T v)
{
	static if (is(T == class))
	{
		if (v is null)
		{
			return JSONValue(null);
		}
	}

	static if (__traits(compiles, T.fromString("")) && __traits(compiles, T.toString()))
	{
		return JSONValue(v.toString());
	}
	// Nullable!T
	else static if (__traits(compiles, v.isNull))
	{
		alias NT = typeof(v.get);

		if (v.isNull)
			return JSONValue(null);
		else
			return toJson(v.get);
	}
	else static if (isSomeString!(T) || isNumeric!(T) || is(T == bool))
	{
		return JSONValue(v);
	}
	else static if (isArray!(T))
	{
		JSONValue[] arr;
		arr.length = v.length;

		foreach (i, e; v)
		{
			arr[i] = toJson(e);
		}

		return JSONValue(arr);
	}
	else
	{
		JSONValue j = JSONValue();
		static foreach (i, field; v.tupleof)
		{
			{
				enum name = __traits(identifier, v.tupleof[i]);
				j[name] = toJson(v.tupleof[i]);
			}
		}

		return j;
	}
}

T fromJson(T)(JSONValue json)
{
	static if (__traits(compiles, T.fromString("")) && __traits(compiles, T.toString()))
	{
		return T.fromString(json.str);
	}
	else static if (isIntegral!T)
	{
		return cast(T) json.integer;
	}
	else static if (isFloatingPoint!T)
	{
		return cast(T) json.floating;
	}
	else static if (isSomeString!T)
	{
		import std.conv;

		return json.str.to!T;
	}
	else static if (is(T == bool))
	{
		return json.boolean;
	}
	else static if (isArray!T)
	{
		alias ET = ElementType!T;
		ET[] arr;
		arr.length = json.array.length;

		foreach (i, e; json.array)
		{
			arr[i] = fromJson!ET(e);
		}

		import std.conv;

		return arr.to!T;
	}
	// Classes and structs
	else
	{
		static if (__traits(compiles, new T()))
		{
			T v = new T();
		}
		else
		{
			T v = T();
		}

		static foreach (i, field; v.tupleof)
		{
			{
				enum name = __traits(identifier, v.tupleof[i]);
				if (name in json)
				{
					alias FT = typeof(v.tupleof[i]);
					v.tupleof[i] = fromJson!FT(json[name]);
				}
			}
		}

		return v;
	}
}