function overloads = calcOverloads(load, maxLoad)
    overloads = load - maxLoad;
    overloads(overloads<=0) = 0;
end