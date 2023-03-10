module Kearsley

using LinearAlgebra
using Statistics

export RMSD, apply_transform, rot_trans

"""
    RMSD(u, v)

Calculates the root mean squared deviation of two sets of points after applying a 
rotation and translation that minimizes the RMSD.

Throws and exception if input matrices do not have the same number of points or if
any of the sets does not have three columns.

# Example
```julia-repl
julia> u = [0 0 0; 1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1; 1 1 1];
julia> v = [1 2 3; 1 1 3; 2 2 3; 1 2 4; 2 1 3; 1 1 4; 2 2 4; 2 1 4];
julia> v += rand(8, 3)*0.1 .- 0.05;
julia> RMSD(u, v)
0.03976994122420646
```
"""
function RMSD(u::Matrix, v::Matrix)

    # calculate bestfit
    rmsd, _ = bestfit(u, v)

    return rmsd

end

"""
    apply_transform(u, v)

Calculates the rotation and translation that minimizes the RMSD and applies
the transformation to `v`.

Throws and exception if input matrices do not have the same number of points or if
any of the sets does not have three columns.

# Example
```julia-repl
julia> u = [0 0 0; 1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1; 1 1 1];
julia> v = [1 2 3; 1 1 3; 2 2 3; 1 2 4; 2 1 3; 1 1 4; 2 2 4; 2 1 4];
julia> v += rand(8, 3)*0.1 .- 0.05;
julia> apply_transform(u, v)
8×3 Matrix{Float64}:
 -0.0311056    0.0103788   -0.0189077
  1.00105      0.00169611  -0.0166774
 -0.00815348   0.960191    -0.0231755
 -0.0135783   -0.00212705   1.0245
  1.02693      1.04732     -0.0327027
  1.01341     -0.0358315    1.03067
 -0.00489211   1.00133      1.0063
  1.01634      1.01704      1.02999
```
"""
function apply_transform(u::Matrix, v::Matrix)

    # calculate rotation and translation
    rotation, translation = rot_trans(u, v)

    return Matrix((rotation*(v' .- translation))')

end

"""
    rot_trans(u, v)

Calculates the rotation and translation that minimizes the RMSD.

Throws and exception if input matrices do not have the same number of points or if
any of the sets does not have three columns.

# Example
```julia-repl
julia> u = [0 0 0; 1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1; 1 1 1]
julia> v = [1 2 3; 1 1 3; 2 2 3; 1 2 4; 2 1 3; 1 1 4; 2 2 4; 2 1 4]
julia> v += rand(8, 3)*0.1 .- 0.05
julia> rot, trans = rot_trans(u, v);
julia> rot
3×3 Matrix{Float64}:
 -0.00911086  -0.999956    -0.00224345
  0.999787    -0.00906772  -0.0185381
  0.018517    -0.00241187   0.999826

julia> trans
3-element Vector{Float64}:
 1.0011488154305659
 1.9878186813737357
 3.0149296587063517
```
"""
function rot_trans(u::Matrix, v::Matrix)

    # calculate bestfit
    _, quaternion = bestfit(u, v)

    # rotation
    rotation = rot_from_quat(quaternion)

    # translation
    translation = mean(v, dims=1)' - inv(rotation) * mean(u, dims=1)'

    return rotation, translation[:]

end

"""
    bestfit(u, v)

Calculates the RMSD and the quaternion for the rotation. Not exported.

Throws and exception if input matrices do not have the same number of points or if
any of the sets does not have three columns.
"""
function bestfit(u::Matrix, v::Matrix)

    # check dimensions
    size(u, 2) == 3 || throw(ArgumentError("u must have three columns"))
    size(v, 2) == 3 || throw(ArgumentError("v must have three columns"))
    size(u, 1) == size(v, 1) || throw(ArgumentError("u and v must have the same number of rows"))

    # centroids
    centroid_u = mean(u, dims=1)
    centroid_v = mean(v, dims=1)

    # centered
    x = u .- centroid_u
    y = v .- centroid_v

    # kearsley matrix
    K = kearsley_matrix(x, y)

    # diagonalize
    rmsd = sqrt(abs(eigvals(K)[1])/size(u)[1])

    # quaternion
    quaternion = eigvecs(K)[:, 1]

    return rmsd, quaternion

end

"""
    kearsley_matrix(x, y)

Calculates the Kearsley matrix. Not exported.
"""
function kearsley_matrix(x::Matrix, y::Matrix)

    # diff and sum
    d = x - y
    s = x + y

    # columns
    d1, d2, d3 = d[:,1], d[:,2], d[:,3]
    s1, s2, s3 = s[:,1], s[:,2], s[:,3]

    # kearsley matrix
    K = zeros(4, 4)
    K[1, 1] = d1' * d1 + d2' * d2 + d3' * d3
    K[2, 1] = s2' * d3 - d2' * s3
    K[3, 1] = d1' * s3 - s1' * d3
    K[4, 1] = s1' * d2 - d1' * s2
    K[2, 2] = s2' * s2 + s3' * s3 + d1' * d1
    K[3, 2] = d1' * d2 - s1' * s2
    K[4, 2] = d1' * d3 - s1' * s3
    K[3, 3] = s1' * s1 + s3' * s3 + d2' * d2
    K[4, 3] = d2' * d3 - s2' * s3
    K[4, 4] = s1' * s1 + s2' * s2 + d3' * d3

    return Symmetric(K, :L)

end

"""
    rot_from_quat(q)

Calculates the rotation matrix with que unit quaternion `q`. Not exported.
"""
function rot_from_quat(q::Vector)

    # quaternion values
    q1, q2, q3, q4 = q

    # rotation
    rotation = zeros(3, 3)
    rotation[1, 1] = q1^2 + q2^2 - q3^2 - q4^2
    rotation[2, 1] = 2(q2*q3 - q1*q4)
    rotation[3, 1] = 2(q2*q4 + q1*q3)
    rotation[1, 2] = 2(q2*q3 + q1*q4)
    rotation[2, 2] = q1^2 + q3^2 - q2^2 - q4^2
    rotation[3, 2] = 2(q3*q4 - q1*q2)
    rotation[1, 3] = 2(q2*q4 - q1*q3)
    rotation[2, 3] = 2(q3*q4 + q1*q2)
    rotation[3, 3] = q1^2 + q4^2 - q2^2 - q3^2

    return rotation
    
end


# end of module
end
