module VonMisesTests

using PyPlot

macro R_str(s)
    s
end


using JuliaFEM.MaterialModels: hookeStiffnessTensor, calculate_stress!, State

function test_von_mises_basic()

    steps = 1000
    strain_max = 0.003
    num_cycles = 3
    E = 200.0e3
    nu =  0.3
    ν = 0.3
    C = hookeStiffnessTensor(E, ν)

    ϵ_tot = zeros(Float64, (steps, 6))
    ϵ_tot2 = zeros(Float64, (steps, 6))
    ϵ_tot3 = zeros(Float64, (steps, 6))

    # Adding only strain in x-axis and counting for the poisson effect
    ϵ_tot[:, 1] = strain_max * sin(2 * pi * linspace(0, num_cycles, steps))
    ϵ_tot[:, 2] = strain_max * sin(2 * pi * linspace(0, num_cycles, steps)).*-ν
    ϵ_tot[:, 3] = strain_max * sin(2 * pi * linspace(0, num_cycles, steps)).*-ν
    ϵ_tot[:, 4] = strain_max / 10 * sin(2 * pi * linspace(0, num_cycles, steps))

    ϵ_last = zeros(Float64, (6))
    ϵᵖ = zeros(Float64, (6))
    σ = zeros(Float64, (6, 1))
    σy =  200.0
    ss = Float64[]
    ee = Float64[]

    eig_stress = zeros(Float64, (3, 3))
    eig_vals = zeros(Float64, (steps, 3))

    function fill_tensor(a, b)
        a[1, 1] = b[1]
        a[2, 2] = b[2]
        a[3, 3] = b[3]

        a[1, 2] = b[6]
        a[1, 3] = b[5]
        a[2, 3] = b[4]

        a[2, 1] = b[6]
        a[3, 1] = b[5]
        a[3, 2] = b[4]
    end

    mat = State(C, σy, zeros(Float64, 6), zeros(Float64, 6))

    info("Starting calculation")
    tic()
    for i=1:steps
        ϵ_new = reshape(ϵ_tot[i, :, :], (6, 1))
        dϵ = ϵ_new - mat.ϵ
        calculate_stress!(dϵ, mat, Val{:vonMises})
        mat.ϵ += vec(dϵ)
        push!(ss, mat.σ[1])
        push!(ee, mat.ϵ[1])

        fill_tensor(eig_stress, mat.σ)
        eig_vals[i, :] = sort(eigvals(eig_stress))
    end
    toc()
    # ================ Plotting =================== #
    n(θ, ϕ) = [sin(θ)*cos(ϕ)
               sin(θ)*sin(ϕ)
               cos(θ)]
    m(θ, ϕ, χ) = [-sin(ϕ)*cos(χ)-cos(θ)*cos(ϕ)*sin(χ)
                   cos(ϕ)*cos(χ)-cos(θ)*sin(ϕ)*sin(χ)
                   sin(θ)*sin(χ)]

    w = [sqrt(2/3) * 200 * m(54.735 * pi / 180, 45 * pi/180, x) for x=0:0.15:(2*pi+0.1)]
    base_vec =  [1 1 1] / sqrt(3)

    for i=-5:5
        tt = [w[x] + vec(base_vec) + 50 * i for x=1:length(w)]
        x = map(x->tt[x][1], collect(1:length(w)))
        y = map(x->tt[x][2], collect(1:length(w)))
        z = map(x->tt[x][3], collect(1:length(w)))
        plot3D(x, y, z, color="blue")
    end

    tt = [w[x] + vec(base_vec) + 50 * -5 for x=1:length(w)]
    x_start = map(x->tt[x][1], collect(1:length(w)))[1:5:end]
    y_start = map(x->tt[x][2], collect(1:length(w)))[1:5:end]
    z_start = map(x->tt[x][3], collect(1:length(w)))[1:5:end]


    tt = [w[x] + vec(base_vec) + 50 * 5 for x=1:length(w)]
    x_end = map(x->tt[x][1], collect(1:length(w)))[1:5:end]
    y_end = map(x->tt[x][2], collect(1:length(w)))[1:5:end]
    z_end = map(x->tt[x][3], collect(1:length(w)))[1:5:end]

    for i=1:length(x_start)
        x = [x_start[i], x_end[i]]
        y = [y_start[i], y_end[i]]
        z = [z_start[i], z_end[i]]
        plot3D(x, y, z, color="blue")
    end


    info("Calculation finished")
    #PyPlot.plot(ee, ss)
    plot3D(eig_vals[:, 1], eig_vals[:, 2], eig_vals[:, 3], color="red")
    PyPlot.title("Stress path and von Mises yield surface")
    PyPlot.xlabel("Eig Stress 1")
    PyPlot.ylabel("Eig Stress 2")
    PyPlot.zlabel("Eig Stress 3")
    PyPlot.grid()
    PyPlot.show()
end

test_von_mises_basic()

end
