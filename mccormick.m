% --------------------------------------------------- McCormick relaxation
UB_I = reshape(repmat(I.UpperBound,n,1),n*ns,1);
LB_I = reshape(repmat(I.LowerBound,n,1),n*ns,1);
UB_G = reshape(G.UpperBound,n*ns,1);
LB_G = reshape(G.LowerBound,n*ns,1);
% UB_SoC = reshape(SoC.UpperBound,n*ns,1);
% LB_SoC = reshape(SoC.LowerBound,n*ns,1);
% if ~stochastic
%     UB_v1 = reshape(v1.UpperBound,n*ns,1);
%     LB_v1 = reshape(v1.LowerBound,n*ns,1);
%     UB_v2 = reshape(v2.UpperBound,n*ns,1);
%     LB_v2 = reshape(v2.LowerBound,n*ns,1);
% end
mcCormick_Ieff = [...
      LB_I.*reshape(G,n*ns,1) + repmat(I,n,1).*LB_G - LB_I.*LB_G - reshape(Ieff,n*ns,1);
      UB_I.*reshape(G,n*ns,1) + repmat(I,n,1).*UB_G - UB_I.*UB_G - reshape(Ieff,n*ns,1);
    - UB_I.*reshape(G,n*ns,1) - repmat(I,n,1).*LB_G + UB_I.*LB_G + reshape(Ieff,n*ns,1);
    - LB_I.*reshape(G,n*ns,1) - repmat(I,n,1).*UB_G + LB_I.*UB_G + reshape(Ieff,n*ns,1)];
% mcCormick_SoCeff = [...
%       LB_SoC.*reshape(G,n*ns,1) + reshape(SoC,n*ns,1).*LB_G - LB_SoC.*LB_G - reshape(SoCeff,n*ns,1);
%       UB_SoC.*reshape(G,n*ns,1) + reshape(SoC,n*ns,1).*UB_G - UB_SoC.*UB_G - reshape(SoCeff,n*ns,1);
%     - UB_SoC.*reshape(G,n*ns,1) - reshape(SoC,n*ns,1).*LB_G + UB_SoC.*LB_G + reshape(SoCeff,n*ns,1);
%     - LB_SoC.*reshape(G,n*ns,1) - reshape(SoC,n*ns,1).*UB_G + LB_SoC.*UB_G + reshape(SoCeff,n*ns,1)];
% if ~stochastic
%     mcCormick_v1eff = [...
%         LB_v1.*reshape(G,n*ns,1) + reshape(v1,n*ns,1).*LB_G - LB_v1.*LB_G - reshape(v1eff,n*ns,1);
%         UB_v1.*reshape(G,n*ns,1) + reshape(v1,n*ns,1).*UB_G - UB_v1.*UB_G - reshape(v1eff,n*ns,1);
%       - UB_v1.*reshape(G,n*ns,1) - reshape(v1,n*ns,1).*LB_G + UB_v1.*LB_G + reshape(v1eff,n*ns,1);
%       - LB_v1.*reshape(G,n*ns,1) - reshape(v1,n*ns,1).*UB_G + LB_v1.*UB_G + reshape(v1eff,n*ns,1)];
%     mcCormick_v2eff = [...
%         LB_v2.*reshape(G,n*ns,1) + reshape(v2,n*ns,1).*LB_G - LB_v2.*LB_G - reshape(v2eff,n*ns,1);
%         UB_v2.*reshape(G,n*ns,1) + reshape(v2,n*ns,1).*UB_G - UB_v2.*UB_G - reshape(v2eff,n*ns,1);
%       - UB_v2.*reshape(G,n*ns,1) - reshape(v2,n*ns,1).*LB_G + UB_v2.*LB_G + reshape(v2eff,n*ns,1);
%       - LB_v2.*reshape(G,n*ns,1) - reshape(v2,n*ns,1).*UB_G + LB_v2.*UB_G + reshape(v2eff,n*ns,1)];
% end