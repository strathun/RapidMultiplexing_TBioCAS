function [ outputArray ] = smart_interleave2( inputMatrix )
%[ outputArray ] = smart_interleave2( inputMatrix )
%   This is a dumb function that automates the use of interleave2 function
%   for variable numbers of arrays. Works up to 10 rows.
%   Inputs:
%       inputMatrix : Matrix containing all of (AND ONLY) the arrays 
%                     (arrays = rows) to be interleaved
%   Outputs:
%       outputArray : interleaved array

[numRows, ~] = size(inputMatrix);

if numRows == 2
    [ outputArray ] = interleave2( inputMatrix( 1, : ), ...
                                   inputMatrix( 2, : ), ...
                                   'col' );
elseif numRows == 3
    [ outputArray ] = interleave2( inputMatrix( 1, : ), ...
                                   inputMatrix( 2, : ), ...
                                   inputMatrix( 3, : ), ...
                                   'col' );
elseif numRows == 4
    [ outputArray ] = interleave2( inputMatrix( 1, : ), ...
                                   inputMatrix( 2, : ), ...
                                   inputMatrix( 3, : ), ...
                                   inputMatrix( 4, : ), ...
                                   'col' );
elseif numRows == 5
    [ outputArray ] = interleave2( inputMatrix( 1, : ), ...
                                   inputMatrix( 2, : ), ...
                                   inputMatrix( 3, : ), ...
                                   inputMatrix( 4, : ), ...
                                   inputMatrix( 5, : ), ...
                                   'col' );
elseif numRows == 6
    [ outputArray ] = interleave2( inputMatrix( 1, : ), ...
                                   inputMatrix( 2, : ), ...
                                   inputMatrix( 3, : ), ...
                                   inputMatrix( 4, : ), ...
                                   inputMatrix( 5, : ), ...
                                   inputMatrix( 6, : ), ...
                                   'col' );
elseif numRows == 7
    [ outputArray ] = interleave2( inputMatrix( 1, : ), ...
                                   inputMatrix( 2, : ), ...
                                   inputMatrix( 3, : ), ...
                                   inputMatrix( 4, : ), ...
                                   inputMatrix( 5, : ), ...
                                   inputMatrix( 6, : ), ...
                                   inputMatrix( 7, : ), ...
                                   'col' );
elseif numRows == 8
    [ outputArray ] = interleave2( inputMatrix( 1, : ), ...
                                   inputMatrix( 2, : ), ...
                                   inputMatrix( 3, : ), ...
                                   inputMatrix( 4, : ), ...
                                   inputMatrix( 5, : ), ...
                                   inputMatrix( 6, : ), ...
                                   inputMatrix( 7, : ), ...
                                   inputMatrix( 8, : ), ...
                                   'col' );
elseif numRows == 9
    [ outputArray ] = interleave2( inputMatrix( 1, : ), ...
                                   inputMatrix( 2, : ), ...
                                   inputMatrix( 3, : ), ...
                                   inputMatrix( 4, : ), ...
                                   inputMatrix( 5, : ), ...
                                   inputMatrix( 6, : ), ...
                                   inputMatrix( 7, : ), ...
                                   inputMatrix( 8, : ), ...
                                   inputMatrix( 9, : ), ...
                                   'col' );
elseif numRows == 10
    [ outputArray ] = interleave2( inputMatrix( 1, : ), ...
                                   inputMatrix( 2, : ), ...
                                   inputMatrix( 3, : ), ...
                                   inputMatrix( 4, : ), ...
                                   inputMatrix( 5, : ), ...
                                   inputMatrix( 6, : ), ...
                                   inputMatrix( 7, : ), ...
                                   inputMatrix( 8, : ), ...
                                   inputMatrix( 9, : ), ...
                                   inputMatrix( 10, : ), ...
                                   'col' );
end

end
