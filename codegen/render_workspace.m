function render_workspace( work, hfname, cfname, embedded_flag )
%RENDER_WORKSPACE Write workspace to header file.

incFile = fopen(hfname, 'w');
srcFile = fopen(cfname, 'w');

% Add an include-guard statement
[~, fname, ~] = fileparts(hfname);
incGuard = [upper(fname), '_H'];
fprintf(incFile, '#ifndef %s\n', incGuard);
fprintf(incFile, '#define %s\n\n', incGuard);

% Include types, constants and private header
fprintf(incFile, '#include \"types.h\"\n');
fprintf(incFile, '#include \"qdldl.h\"\n');
fprintf(incFile, '#include \"qdldl_interface.h\"\n\n');

fprintf(srcFile, '#include \"types.h\"\n');
fprintf(srcFile, '#include \"qdldl.h\"\n');
fprintf(srcFile, '#include \"qdldl_interface.h\"\n\n');

% Write data structure
write_data_src(srcFile, work.data);
write_data_inc(incFile, work.data);

% Write settings structure
write_settings_src(srcFile, work.settings, embedded_flag);
write_settings_inc(incFile, work.settings, embedded_flag);

% Write scaling structure
write_scaling_src(srcFile, work.scaling);
write_scaling_inc(incFile, work.scaling);

% Write linsys_solver structure
write_linsys_solver_src(srcFile, work.linsys_solver, embedded_flag);
write_linsys_solver_inc(incFile, work.linsys_solver, embedded_flag);

% Define empty solution structure
write_solution_src(srcFile, work.data.n, work.data.m);
write_solution_inc(incFile, work.data.n, work.data.m);

% Define info structure
write_info_src(srcFile);
write_info_inc(incFile);

% Define workspace structure
write_workspace_src(srcFile, work.data.n, work.data.m, work.rho_vectors, embedded_flag);
write_workspace_inc(incFile, work.data.n, work.data.m, work.rho_vectors, embedded_flag);

% The endif for the include-guard
fprintf(incFile, '#endif // ifndef %s\n', incGuard);

fclose(incFile);
fclose(srcFile);

end



function write_data_src( f, data )
%WRITE_DATA_SRC Write data structure to file.

fprintf(f, '// Define data structure\n');

% Define matrix P
write_mat(f, data.P, 'Pdata');

% Define matrix A
write_mat(f, data.A, 'Adata');

% Define other data vectors
write_vec(f, data.q, 'qdata', 'c_float');
write_vec(f, data.l, 'ldata', 'c_float');
write_vec(f, data.u, 'udata', 'c_float');

% Define data structure
fprintf(f, 'OSQPData data = {');
fprintf(f, '%d, ', data.n);
fprintf(f, '%d, ', data.m);
fprintf(f, '&Pdata, &Adata, qdata, ldata, udata');
fprintf(f, '};\n\n');

end

function write_data_inc( f, data )
%WRITE_DATA_INC Write data structure prototypes to file.

fprintf(f, '// Data structure prototypes\n');

% Define matrix P
write_mat_extern(f, data.P, 'Pdata');

% Define matrix A
write_mat_extern(f, data.A, 'Adata');

% Define other data vectors
write_vec_extern(f, data.q, 'qdata', 'c_float');
write_vec_extern(f, data.l, 'ldata', 'c_float');
write_vec_extern(f, data.u, 'udata', 'c_float');

% Define data structure
fprintf(f, 'extern OSQPData data;\n\n');

end


function write_settings_src( f, settings, embedded_flag )
%WRITE_SETTINGS_SRC Write settings structure to file.

fprintf(f, '// Define settings structure\n');
fprintf(f, 'OSQPSettings settings = {');
fprintf(f, '(c_float)%.20f, ', settings.rho);
fprintf(f, '(c_float)%.20f, ', settings.sigma);
fprintf(f, '%d, ',             settings.scaling);

if embedded_flag ~= 1
    fprintf(f, '%d, ', settings.adaptive_rho);
    fprintf(f, '%d, ', settings.adaptive_rho_interval);
    fprintf(f, '(c_float)%.20f,', settings.adaptive_rho_tolerance);
end

fprintf(f, '%d, ',             settings.max_iter);
fprintf(f, '(c_float)%.20f, ', settings.eps_abs);
fprintf(f, '(c_float)%.20f, ', settings.eps_rel);
fprintf(f, '(c_float)%.20f, ', settings.eps_prim_inf);
fprintf(f, '(c_float)%.20f, ', settings.eps_dual_inf);
fprintf(f, '(c_float)%.20f, ', settings.alpha);
fprintf(f, '(enum linsys_solver_type) LINSYS_SOLVER, ');


fprintf(f, '%d, ', settings.scaled_termination);
fprintf(f, '%d, ', settings.check_termination);
fprintf(f, '%d, ', settings.warm_start);

fprintf(f, '};\n\n');

end

function write_settings_inc( f, settings, embedded_flag )
%WRITE_SETTINGS_INC Write prototype for settings structure to file.

fprintf(f, '// Settings structure prototype\n');
fprintf(f, 'extern OSQPSettings settings;\n\n');

end


function write_scaling_src( f, scaling )
%WRITE_SCALING_SRC Write scaling structure to file.

fprintf(f, '// Define scaling structure\n');

if ~isempty(scaling)
    write_vec(f, scaling.D,    'Dscaling',    'c_float');
    write_vec(f, scaling.Dinv, 'Dinvscaling', 'c_float');
    write_vec(f, scaling.E,    'Escaling',    'c_float');
    write_vec(f, scaling.Einv, 'Einvscaling', 'c_float');
    fprintf(f, 'OSQPScaling scaling = {');
    fprintf(f, '(c_float)%.20f, ', scaling.c);
    fprintf(f, 'Dscaling, Escaling, ');
    fprintf(f, '(c_float)%.20f, ', scaling.cinv);
    fprintf(f, 'Dinvscaling, Einvscaling};\n\n');
else
    fprintf(f, 'OSQPScaling scaling;\n\n');
end

end


function write_scaling_inc( f, scaling )
%WRITE_SCALING_INC Write prototypes for the scaling structure to file.

fprintf(f, '// Scaling structure prototypes\n');

if ~isempty(scaling)
    write_vec_extern(f, scaling.D,    'Dscaling',    'c_float');
    write_vec_extern(f, scaling.Dinv, 'Dinvscaling', 'c_float');
    write_vec_extern(f, scaling.E,    'Escaling',    'c_float');
    write_vec_extern(f, scaling.Einv, 'Einvscaling', 'c_float');
end

fprintf(f, 'extern OSQPScaling scaling;\n\n');


end

function write_linsys_solver_src( f, linsys_solver, embedded_flag )
%WRITE_LINSYS_SOLVER_SRC Write linsys_solver structure to file.

fprintf(f, '// Define linsys_solver structure\n');
write_mat(f, linsys_solver.L, 'linsys_solver_L')
write_vec(f, linsys_solver.Dinv, 'linsys_solver_Dinv', 'c_float')
write_vec(f, linsys_solver.P, 'linsys_solver_P', 'c_int')
fprintf(f, 'c_float linsys_solver_bp[%d];\n', length(linsys_solver.Dinv));  % Empty rhs

if embedded_flag ~= 1
    write_vec(f, linsys_solver.Pdiag_idx, 'linsys_solver_Pdiag_idx', 'c_int');
    write_mat(f, linsys_solver.KKT,       'linsys_solver_KKT');
    write_vec(f, linsys_solver.PtoKKT,    'linsys_solver_PtoKKT',    'c_int');
    write_vec(f, linsys_solver.AtoKKT,    'linsys_solver_AtoKKT',    'c_int');
    write_vec(f, linsys_solver.rhotoKKT,  'linsys_solver_rhotoKKT',  'c_int');
    write_vec(f, linsys_solver.D,         'linsys_solver_D',         'QDLDL_float');
    write_vec(f, linsys_solver.etree,     'linsys_solver_etree',     'QDLDL_int');
    write_vec(f, linsys_solver.Lnz,       'linsys_solver_Lnz',       'QDLDL_int');
    fprintf(f, 'QDLDL_int   linsys_solver_iwork[%d];\n', length(linsys_solver.iwork));
    fprintf(f, 'QDLDL_bool  linsys_solver_bwork[%d];\n', length(linsys_solver.bwork));
    fprintf(f, 'QDLDL_float linsys_solver_fwork[%d];\n', length(linsys_solver.fwork));
end

fprintf(f, 'qdldl_solver linsys_solver = ');
fprintf(f, '{QDLDL_SOLVER, &solve_linsys_qdldl, ');
if embedded_flag ~= 1
    fprintf(f, ['&update_linsys_solver_matrices_qdldl, &update_linsys_solver_rho_vec_qdldl, ', ...
            '&linsys_solver_L, linsys_solver_Dinv, linsys_solver_P, linsys_solver_bp, linsys_solver_Pdiag_idx, ', ...
            num2str(linsys_solver.Pdiag_n), ', &linsys_solver_KKT, linsys_solver_PtoKKT, linsys_solver_AtoKKT, linsys_solver_rhotoKKT, ', ...
            'linsys_solver_D, linsys_solver_etree, linsys_solver_Lnz, linsys_solver_iwork, linsys_solver_bwork, linsys_solver_fwork};\n\n']);
else
    fprintf(f, '&linsys_solver_L, linsys_solver_Dinv, linsys_solver_P, linsys_solver_bp};\n\n');
end

end


function write_linsys_solver_inc( f, linsys_solver, embedded_flag )
%WRITE_LINSYS_SOLVER_INC Write prototypes for linsys_solver structure to file.

fprintf(f, '// Prototypes for linsys_solver structure\n');
write_mat_extern(f, linsys_solver.L, 'linsys_solver_L')
write_vec_extern(f, linsys_solver.Dinv, 'linsys_solver_Dinv', 'c_float')
write_vec_extern(f, linsys_solver.P, 'linsys_solver_P', 'c_int')
fprintf(f, 'extern c_float linsys_solver_bp[%d];\n', length(linsys_solver.Dinv));  % Empty rhs

if embedded_flag ~= 1
    write_vec_extern(f, linsys_solver.Pdiag_idx, 'linsys_solver_Pdiag_idx', 'c_int');
    write_mat_extern(f, linsys_solver.KKT,       'linsys_solver_KKT');
    write_vec_extern(f, linsys_solver.PtoKKT,    'linsys_solver_PtoKKT',    'c_int');
    write_vec_extern(f, linsys_solver.AtoKKT,    'linsys_solver_AtoKKT',    'c_int');
    write_vec_extern(f, linsys_solver.rhotoKKT,  'linsys_solver_rhotoKKT',  'c_int');
    write_vec_extern(f, linsys_solver.D,         'linsys_solver_D',         'QDLDL_float');
    write_vec_extern(f, linsys_solver.etree,     'linsys_solver_etree',     'QDLDL_int');
    write_vec_extern(f, linsys_solver.Lnz,       'linsys_solver_Lnz',       'QDLDL_int');
    fprintf(f, 'extern QDLDL_int   linsys_solver_iwork[%d];\n', length(linsys_solver.iwork));
    fprintf(f, 'extern QDLDL_bool  linsys_solver_bwork[%d];\n', length(linsys_solver.bwork));
    fprintf(f, 'extern QDLDL_float linsys_solver_fwork[%d];\n', length(linsys_solver.fwork));
end

fprintf(f, 'extern qdldl_solver linsys_solver;\n\n');

end


function write_solution_src( f, n, m )
%WRITE_SOLUTION_SRC Preallocate solution vectors

fprintf(f, '// Define solution\n');
fprintf(f, 'c_float xsolution[%d];\n', n);
fprintf(f, 'c_float ysolution[%d];\n\n', m);
fprintf(f, 'OSQPSolution solution = {xsolution, ysolution};\n\n');

end

function write_solution_inc( f, n, m )
%WRITE_SOLUTION_INC Prototypes for solution vectors

fprintf(f, '// Prototypes for solution\n');
fprintf(f, 'extern c_float xsolution[%d];\n', n);
fprintf(f, 'extern c_float ysolution[%d];\n\n', m);
fprintf(f, 'extern OSQPSolution solution;\n\n');

end


function write_info_src( f )
%WRITE_INFO_SRC Preallocate info structure

fprintf(f, '// Define info\n');
fprintf(f, 'OSQPInfo info = {0, "Unsolved", OSQP_UNSOLVED, (c_float)0.0, (c_float)0.0, (c_float)0.0};\n\n');

end

function write_info_inc( f )
%WRITE_INFO_INC Prototype for info structure

fprintf(f, '// Prototype for info structure\n');
fprintf(f, 'extern OSQPInfo info;\n\n');

end


function write_workspace_src( f, n, m, rho_vectors, embedded_flag )
%WRITE_WORKSPACE_SRC Preallocate workspace structure and populate rho_vectors

fprintf(f, '// Define workspace\n');
write_vec(f, rho_vectors.rho_vec,     'work_rho_vec',     'c_float');
write_vec(f, rho_vectors.rho_inv_vec, 'work_rho_inv_vec', 'c_float');
if embedded_flag ~= 1
    write_vec(f, rho_vectors.constr_type, 'work_constr_type', 'c_int');
end
fprintf(f, 'c_float work_x[%d];\n', n);
fprintf(f, 'c_float work_y[%d];\n', m);
fprintf(f, 'c_float work_z[%d];\n', m);
fprintf(f, 'c_float work_xz_tilde[%d];\n', n+m);
fprintf(f, 'c_float work_x_prev[%d];\n', n);
fprintf(f, 'c_float work_z_prev[%d];\n', m);
fprintf(f, 'c_float work_Ax[%d];\n', m);
fprintf(f, 'c_float work_Px[%d];\n', n);
fprintf(f, 'c_float work_Aty[%d];\n', n);
fprintf(f, 'c_float work_delta_y[%d];\n', m);
fprintf(f, 'c_float work_Atdelta_y[%d];\n', n);
fprintf(f, 'c_float work_delta_x[%d];\n', n);
fprintf(f, 'c_float work_Pdelta_x[%d];\n', n);
fprintf(f, 'c_float work_Adelta_x[%d];\n', m);
fprintf(f, 'c_float work_D_temp[%d];\n', n);
fprintf(f, 'c_float work_D_temp_A[%d];\n', n);
fprintf(f, 'c_float work_E_temp[%d];\n\n', m);

fprintf(f, 'OSQPWorkspace workspace = {\n');
fprintf(f, '&data, (LinSysSolver *)&linsys_solver,\n');
fprintf(f, 'work_rho_vec, work_rho_inv_vec,\n');
if embedded_flag ~= 1
    fprintf(f, 'work_constr_type,\n');
end
fprintf(f, 'work_x, work_y, work_z, work_xz_tilde,\n');
fprintf(f, 'work_x_prev, work_z_prev,\n');
fprintf(f, 'work_Ax, work_Px, work_Aty,\n');
fprintf(f, 'work_delta_y, work_Atdelta_y,\n');
fprintf(f, 'work_delta_x, work_Pdelta_x, work_Adelta_x,\n');
fprintf(f, 'work_D_temp, work_D_temp_A, work_E_temp,\n');
fprintf(f, '&settings, &scaling, &solution, &info};\n\n');

end

function write_workspace_inc( f, n, m, rho_vectors, embedded_flag )
%WRITE_WORKSPACE_INC Prototypes for the workspace structure and rho_vectors

fprintf(f, '// Prototypes for the workspace\n');
write_vec_extern(f, rho_vectors.rho_vec,     'work_rho_vec',     'c_float');
write_vec_extern(f, rho_vectors.rho_inv_vec, 'work_rho_inv_vec', 'c_float');
if embedded_flag ~= 1
    write_vec_extern(f, rho_vectors.constr_type, 'work_constr_type', 'c_int');
end
fprintf(f, 'extern c_float work_x[%d];\n', n);
fprintf(f, 'extern c_float work_y[%d];\n', m);
fprintf(f, 'extern c_float work_z[%d];\n', m);
fprintf(f, 'extern c_float work_xz_tilde[%d];\n', n+m);
fprintf(f, 'extern c_float work_x_prev[%d];\n', n);
fprintf(f, 'extern c_float work_z_prev[%d];\n', m);
fprintf(f, 'extern c_float work_Ax[%d];\n', m);
fprintf(f, 'extern c_float work_Px[%d];\n', n);
fprintf(f, 'extern c_float work_Aty[%d];\n', n);
fprintf(f, 'extern c_float work_delta_y[%d];\n', m);
fprintf(f, 'extern c_float work_Atdelta_y[%d];\n', n);
fprintf(f, 'extern c_float work_delta_x[%d];\n', n);
fprintf(f, 'extern c_float work_Pdelta_x[%d];\n', n);
fprintf(f, 'extern c_float work_Adelta_x[%d];\n', m);
fprintf(f, 'extern c_float work_D_temp[%d];\n', n);
fprintf(f, 'extern c_float work_D_temp_A[%d];\n', n);
fprintf(f, 'extern c_float work_E_temp[%d];\n\n', m);

fprintf(f, 'extern OSQPWorkspace workspace;\n\n');

end


function write_vec(f, vec, name, vec_type)
%WRITE_VEC Write vector to file.

fprintf(f, '%s %s[%d] = {\n', vec_type, name, length(vec));

% Write vector elements
for i = 1 : length(vec)
    if strcmp(vec_type, 'c_float')
        fprintf(f, '(c_float)%.20f,\n', vec(i));
    else
        fprintf(f, '%i,\n', vec(i));
    end
end
fprintf(f, '};\n');

end

function write_vec_extern(f, vec, name, vec_type)
%WRITE_VEC_EXTERN Write vector prototype to file.

fprintf(f, 'extern %s %s[%d];\n', vec_type, name, length(vec));

end


function write_mat(f, mat, name)
%WRITE_MAT Write matrix in CSC format to file.

write_vec(f, mat.i, [name, '_i'], 'c_int');
write_vec(f, mat.p, [name, '_p'], 'c_int');
write_vec(f, mat.x, [name, '_x'], 'c_float');

fprintf(f, 'csc %s = {', name);
fprintf(f, '%d, ', mat.nzmax);
fprintf(f, '%d, ', mat.m);
fprintf(f, '%d, ', mat.n);
fprintf(f, '%s_p, ', name);
fprintf(f, '%s_i, ', name);
fprintf(f, '%s_x, ', name);
fprintf(f, '%d};\n', mat.nz);

end

function write_mat_extern(f, mat, name)
%WRITE_MAT_EXTERN Write matrix the prototype for the matrix.

write_vec_extern(f, mat.i, [name, '_i'], 'c_int');
write_vec_extern(f, mat.p, [name, '_p'], 'c_int');
write_vec_extern(f, mat.x, [name, '_x'], 'c_float');

fprintf(f, 'extern csc %s;\n', name);

end
