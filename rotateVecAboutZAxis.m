function [rot_z] = rotateVecAboutZAxis(rang, vec)
    rot_z = [cos(rang), -sin(rang), 0;
          sin(rang), cos(rang), 0;
          0, 0, 1] * vec;
end