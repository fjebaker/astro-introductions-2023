using Plots, Colors, Images, FileIO, ImageMagick
using Gradus

function cartesian_line(m::AbstractMetric, x::SVector{4}, v::SVector{4})
    x_cart = Gradus.to_cartesian(x)
    # an infinitesimal step back
    T = Gradus.lnrbasis_matrix(m, x)
    vv = T * v
    v_cart = SVector(vv[2], vv[3], vv[4]) ./ vv[1]
    dv = -Gradus._spher_to_cart_jacobian(x[3], x[4], x[2]) * v_cart

    v_cart = (dv ./ √(dv[1]^2 + dv[2]^2 + dv[3]^2))
    x_prev = @. x_cart - 1e-1 * v_cart
    x_next = @. x_cart + 1e-1 * v_cart

    (x_prev, x_next)
end

struct RotatingDisc{T} <: Gradus.AbstractAccretionDisc{T}
    radius::T
    r::T
    rotation::T
end

Gradus.optical_property(::Type{<:RotatingDisc}) = Gradus.OpticallyThin()
Gradus.inner_radius(disc::RotatingDisc) = disc.r - disc.radius

function Gradus.distance_to_disc(disc::RotatingDisc, x4; gtol)
    ρ = Gradus._equatorial_project(x4)
    if (ρ < disc.r - disc.radius) || (ρ > disc.r + disc.radius)
        return one(eltype(x4))
    end
    # rotate back 
    if abs(mod2pi(x4[4]) - disc.rotation) < 0.01
        return Gradus._spinaxis_project(x4, signed = false) - Gradus._gtol_error(gtol, x4) - disc.radius
    else
        return one(eltype(x4))
    end
end

function painter(disc, image; scale = 2.22)
    height, width = size(image)
    x_mid = width ÷ 2
    y_mid = height ÷ 2
    function painter(m, gp, t)
        if gp.status != StatusCodes.IntersectedWithGeometry
            return zero(eltype(image))
        end
        y = -Gradus._spinaxis_project(gp.x, signed = true)
        x = -(Gradus._equatorial_project(gp.x) - disc.r)
        
        ix = trunc(Int, (x / disc.r) * x_mid * scale) + x_mid
        iy = trunc(Int, (y / disc.r) * y_mid * scale) + y_mid
        
        # make sure no out of bounds
        i = clamp(ix, 1, width)
        j = clamp(iy, 1, height)

        image[j, i]
    end
end

function trace_face(m, x, disc, image)
    a, b, cache = prerendergeodesics(
        m,
        x,
        disc,
        2000.0
        ;
        image_width = 300 * 2,
        image_height = 200 * 2,
        αlims = (-30, 30),
        βlims = (-20, 20),
        verbose = true,
    )

    pf = painter(disc, image)
    map(cache.points) do gp
        pf(m, gp, 2000.0)
    end
end

m = KerrMetric(1.0, 0.998)
x = SVector(0.0, 1000.0, deg2rad(86), 0.0)
image = load("input.jpg")

N = 120
frames = map(enumerate(range(0, 360 - (360 / N), N))) do (i, ϕ)
    @info "$i of $N"
    @time trace_face(m, x, RotatingDisc(6.0, 15.0, deg2rad(ϕ)), image)
end

# create the axes
α, β = Gradus.impact_axes(size(frames[1], 2), size(frames[1], 1), (-30, 30), (-20, 20))

plot_frames = @animate for frame in reverse(frames)
    plot(α, β, reverse(frame, dims=1), legend = false, size = (700, 500), aspect_ratio = 1, xlabel = "α", ylabel = "β")
end

gif(plot_frames, "output.gif", fps=23)