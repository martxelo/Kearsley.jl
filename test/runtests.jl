using Kearsley
using Test

@testset "Kearsley.jl" begin
    
    # variables
    trans = [1, 2, 3]
    rot = [0 -1 0; 1 0 0; 0 0 1]
    u = [0 0 0; 1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1; 1 1 1]
    v = (inv(rot)*u')' .+ reshape(trans, 1, 3)

    # check values are ok
    @test ≈(RMSD(u, v), 0, atol=1e-6)
    @test ≈(apply_transform(u, v), u, atol=1e-6)
    @test ≈(rot_trans(u, v)[1], rot, atol=1e-6)
    @test ≈(rot_trans(u, v)[2], trans, atol=1e-6)

    # test exceptions
    @test_throws ArgumentError RMSD(u[:,1:2], v)
    @test_throws ArgumentError RMSD(u, v[:,1:2])
end
