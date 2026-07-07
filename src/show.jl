function Base.show(io::IO, x::AbstractSuperposition)
    shape = size(x)
    data_unit = _show_unit(unit(x))
    axis1_unit = _show_unit(unit(x, :axis1))
    axis2_unit = _show_unit(unit(x, :axis2))
    io_fancy = IOContext(io, :fancy_exponent => true)
    print(io_fancy, shape[1], "×", shape[2], " ", _superposition_display_name(x),
        "{", data_unit, "}{", axis1_unit, "}{", axis2_unit, "}")
end

function Base.show(io::IO, x::AbstractSuperposition1D)
    shape = size(x)
    data_unit = _show_unit(unit(x))
    axis_unit = _show_unit(unit(x, :axis))
    io_fancy = IOContext(io, :fancy_exponent => true)
    print(io_fancy, shape[1], "-element ", _superposition_display_name(x),
        "{", data_unit, "}{", axis_unit, "}")
end

function Base.show(io::IO, ::MIME"text/plain", x::AbstractSuperposition)
    show(io, x)
    println(io, " with ", coordinates(x), " coordinates and axes:")
    _show_axis(io, x.axesnames[1], x.axestypes[1], x.axis1)
    _show_axis(io, x.axesnames[2], x.axestypes[2], x.axis2)
    println(io, "and data:")
    Base.print_matrix(io, x.data)
end

function Base.show(io::IO, ::MIME"text/plain", x::AbstractSuperposition1D)
    show(io, x)
    println(io, " with axis:")
    _show_axis(io, x.axisname, x.axistype, x.axis)
    println(io, "and data:")
    Base.print_matrix(io, reshape(x.data, :, 1))
end

function _superposition_display_name(x)
    return String(nameof(typeof(x)))
end

function _show_unit(u)
    return u == NoUnits ? 1 : u
end

function _show_axis(io, name, type, axis)
    print(io, "  :", name)
    name == type || print(io, " (", type, ")")
    print(io, ": [")
    if length(axis) <= 6
        _show_axis_values(io, axis)
    else
        _show_axis_values(io, (axis[1], axis[2], axis[3]))
        print(io, ", …, ")
        n = length(axis)
        _show_axis_values(io, (axis[n - 2], axis[n - 1], axis[n]))
    end
    println(io, "]")
end

function _show_axis_values(io, values)
    for (i, value) in enumerate(values)
        i > 1 && print(io, ", ")
        show(IOContext(io, :fancy_exponent => true), value)
    end
end
