# HW_TCL_Scripts
### Compilation of TCL Scripts for HW

- 1 <ins><strong>script_message_window</strong></ins>: Script that shows a pop-up window with a message.
- 2 <ins><strong>script_plot_centroid</strong></ins>: Script that plots a free node at the element centroid position.
- 3 <ins><strong>script_distance_centroid_surf</strong></ins>: Script that shows the distance between an element (its centroid) and a geometric surface.
- 4 <ins><strong>script_offset_with_reference_surfs</strong></ins>: Script that sets the shell element ofset (ZOFFS) so that one of the elemnts faces lays on a geometrical reference surface.
- 5 <ins><strong>script_get_CFAST_SHID</strong></ins>: Script that returns the SHIDA and SHIDB from a CFAST element.
- 6 <ins><strong>script_id_FE_from_conector</strong></ins>: Script that returns the FE IDs associated to a connector.
- 7 <ins><strong>script_get_CBUSH_associated_props</strong></ins>: Script that gives information of a CBUSH element as well as information of the adjacent elements of the joint.
- 8 <ins><strong>proc_get_disp_elems_byconfig</strong></ins>: A procedure that returns the displayed elements of one or more configurations. A procedure that returns the elements other than certain configurations.
- 9 <ins><strong>script_material_orientation_check</strong></ins>: Script that checks that all elements from composite properties have a material orientation.
- 10 <ins><strong>script_set_rbe2_cte</strong></ins>: Script that sets the CTE of the displayed RBE2 elements.
- 11 <ins><strong>script_set_rbe3_cte</strong></ins>: Script that sets the CTE of the displayed RBE3 elements.
- 12 <ins><strong>script_rbe3_to_rbe2</strong></ins>: Script that converts the displayed RBE3 elements to RBE2 elements.
- 13 <ins><strong>script_rbe2_to_rbe3</strong></ins>: Script that converts the displayed RBE2 elements to RBE3 elements. Weigth 1.0 and dofs 123 for independent nodes.
- 14 <ins><strong>script_get_rivet_associated_props</strong></ins>: Script that search for the displayed rivets (CBUSH, CFAST, etc) and returns information about the "attached" elements and its materials and properties.
- 15 <ins><strong>tool_orientate_rivet_head</strong></ins>: Tool to orient a joint by defining whether the distance of its GA node with respect to a reference node is greater or less than the distance of the node corresponding to the nut or thread, GB.
