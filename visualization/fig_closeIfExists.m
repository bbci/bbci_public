function close_if_exists(h)
%CLOSE_IF_EXISTS - Close figure window(s) without complaining if nonexisting

figure_handles= sort(findobj('Type','figure'));
to_be_closed= intersect(h, figure_handles,'legacy');
close(to_be_closed);
