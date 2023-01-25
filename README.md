# Kearsley

Package for structural comparisons of 3D points. Uses the Kearsley algorithm for calculating the rotation and translation that minimize the RMSD of two sets of 3D points.

Original paper by Simon K. Kearsley: _On the orthogonal transformation used for structural comparisons_ https://doi.org/10.1107/S0108767388010128.

The algorithm does the same than the [Kabsch algoritm](https://en.wikipedia.org/wiki/Kabsch_algorithm) but with the quaternion method.

## Usage

Given two sets of points:

```julia-repl
julia> using Kearsley
julia> u = [0 0 0; 1 0 0; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1; 1 1 1];
julia> v = [1 2 3; 1 1 3; 2 2 3; 1 2 4; 2 1 3; 1 1 4; 2 2 4; 2 1 4];
julia> v += rand(8, 3)*0.1 .- 0.05;
```

You have three useful functions:
 - `RMSD(u, v)`: returns the optimal RMSD.
 - `rot_trans(u, v)`: returns the rotation and translation that should be applied to the second set of points.
 - `apply_transform(u, v)`: applies the rotation and translation to the second set of points.

```julia-repl
julia> RMSD(u, v)
0.03976994122420646

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

The three functions are independent. All of them calculate the bestfit and return only the expected values. You don't need to run them in any order.

## Aplications

- Compare a set of measured points with their theoretical positions.
- In robotics compare two sets of points measured in different coordinate systems and get the transformation between both coordinate systems. 
- It is possible to use it in a 2D space fixing the third coordinate to zero.
