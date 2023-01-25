module Kearsley

using LinearAlgebra
using Statistics

export RMSD, apply_transform, rot_trans


function RMSD(u::Matrix, v::Matrix)

    # calculate bestfit
    rmsd, _ = bestfit(u, v)

    return rmsd

end


function apply_transform(u::Matrix, v::Matrix)

    # calculate rotation and translation
    rotation, translation = rot_trans(u, v)

    return (rotation*(v' .- translation))'

end


function rot_trans(u::Matrix, v::Matrix)

    # calculate bestfit
    _, quaternion = bestfit(u, v)

    # rotation
    rotation = rot_from_quat(quaternion)

    # translation
    translation = mean(v, dims=1)' - inv(rotation) * mean(u, dims=1)'

    return rotation, translation[:]

end


function bestfit(u::Matrix, v::Matrix)

    # check dimensions
    size(u, 2) == 3 || throw(ArgumentError("u must have three columns"))
    size(v, 2) == 3 || throw(ArgumentError("v must have three columns"))

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
