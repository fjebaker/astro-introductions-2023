using Printf, CairoMakie, Makie
using Statistics, GLM

# burning time sources:

# https://www.srf.ch/news/regional/zuerich-schaffhausen/super-sommer-der-kopf-des-boeoeggs-ist-nach-7-23-weg
# https://www.srf.ch/news/regional/zuerich-schaffhausen/sechselaeuten-2019-so-vertreibt-die-stadt-zuerich-den-winter
# https://www.srf.ch/radio-srf-1/radio-srf-1-wie-zuverlaessig-ist-der-boeoeggometer

function parse_lines(lines)
    temp_data = Pair{Float64,Float64}[]
    for line in lines
        entries = split(line)
        if length(entries) == 0
            continue
        end
        year::Int = try
            parse(Int, entries[1])
        catch err
            if err isa ArgumentError
                continue
            else
                throw(err)
            end
        end

        temps =
            filter(!isnan, map(i -> i == "NA" ? NaN64 : parse(Float64, i), entries[2:end]))

        avg = mean(temps)
        push!(temp_data, year => avg)
    end

    temp_data
end

# parse the swiss data
lines = readlines("climate-data-swissmean_regSwiss_1.3.txt")
temp_data = parse_lines(lines)

# year => (min, sec)
data = [
    1980 => (17, 0),
    1981 => (14, 10),
    1982 => (13, 0),
    1983 => (24, 20),
    1984 => (22, 0),
    1985 => (24, 0),
    1986 => (14, 0),
    1987 => (17, 0),
    1988 => (40, 0),
    1989 => (24, 0),
    1990 => (10, 30),
    1991 => (12, 00),
    1992 => (10, 13),
    1993 => (23, 30),
    1994 => (21, 55),
    1995 => (5, 51),
    1996 => (8, 00),
    1997 => (7, 30),
    1998 => (10, 13),
    1999 => (23, 52),
    2000 => (16, 45),
    2001 => (26, 23),
    2002 => (12, 24),
    2003 => (5, 42),
    2004 => (11, 42),
    2005 => (17, 52),
    2006 => (10, 28),
    2007 => (12, 09),
    2008 => (26, 01),
    2009 => (12, 55),
    2010 => (12, 54),
    2011 => (10, 56),
    2012 => (12, 07),
    2013 => (35, 11),
    2014 => (7, 23),
    2016 => (43, 34),
    2017 => (9, 56),
    2018 => (20, 31),
    2019 => (17, 44),
    2021 => (12, 57),
    2022 => (37, 59),
    2023 => (57, 00),
]

to_seconds(t) = t[1] * 60 + t[2]

function min_formatter(values)
    map(values) do x
        mins = x ÷ 60
        sec = x - 60 * mins
        # @sprintf "%.0fm %02.0fs" mins sec
        @sprintf "%.0f" mins
    end
end

years1 = first.(data)
secs1 = to_seconds.(last.(data))

temp_view = last.(temp_data)[end-length(secs1)+1:end]


res = lm(@formula(temp_view ~ secs1), (; secs1, temp_view))
xs = collect(range(0, 4000, 300))
pred = predict(res, (; secs1 = xs), interval = :prediction, level = 0.95)

begin
    fig = Figure(resolution = (600, 400))

    ax2 = Axis(
        fig[1, 1],
        yaxisposition = :right,
        yticks = LinearTicks(5),
        ygridvisible = false,
        ylabel = "Area-Mean Temperature [°C]",
        xlabel = "Year",
    )
    ax = Axis(
        fig[1, 1],
        ytickformat = min_formatter,
        yticks = LinearTicks(6),
        ylabel = "TtE [minutes]",
    )

    Label(
        fig[1, 1, Top()],
        "Böögg Time to Explode (TtE)",
        padding = (0, 0, 20, 0),
        fontsize = 20,
        font = :bold,
    )

    axmini = Axis(
        fig[1, 1],
        width = Relative(0.35),
        height = Relative(0.35),
        halign = 0.12,
        valign = 0.95,
        xlabel = L"t_\text{TtE}",
        ylabel = L"T_\text{avg}",
    )
    hidedecorations!(axmini, label = false)
    translate!(axmini.scene, 0, 0, 10)
    # this needs separate translation as well, since it's drawn in the parent scene
    translate!(axmini.elements[:background], 0, 0, 9)

    colors = Iterators.Stateful(Iterators.Cycle(Makie.wong_colors()))
    c1 = popfirst!(colors)
    c2 = popfirst!(colors)

    scatterlines!(ax, years1, secs1, color = c1)
    scatterlines!(ax2, first.(temp_data), last.(temp_data), color = c2, markersize = 7.0)

    scatter!(axmini, secs1, temp_view, markersize = 6.0)
    lines!(axmini, xs, pred.prediction)
    band!(axmini, xs, pred.lower, pred.upper, color = RGBAf(c2.r, c2.g, c2.b, 0.3))

    ylims!(axmini, 3.3, 8.7)
    xlims!(axmini, 0, 3800)

    Legend(
        fig[1, 1],
        [[MarkerElement(color = c1, marker = :●)], [MarkerElement(color = c2, marker=:●, markersize=6.0)]],
        [L"t_\text{TtE}", L"T_\text{avg}"],
        orientation = :horizontal,
        width = Relative(0.36),
        height = Relative(0.1),
        halign = 0.95,
        valign = 0.95,
        labelsize = 18,
    )

    linkxaxes!(ax2, ax)
    hidexdecorations!(ax)
    xlims!(ax, 1978, 2026)
    ylims!(ax, nothing, 4720)
    ylims!(ax2, nothing, 9.5)

    R2 = @sprintf "%.3f" r2(res)
    text!(ax, 2001, 55 * 60; text = L"R^2 = %$(R2)", fontsize = 22)
    fig
end

Makie.save("boogg.png", fig, px_per_unit = 3)
