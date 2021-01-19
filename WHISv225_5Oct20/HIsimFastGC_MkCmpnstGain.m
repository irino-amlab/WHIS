%
%  HIsimFastGC_MkCmpnstGain.m
%  Irino, T.
%  Created:  12 Dec 18 (from Check_HIsim_IOfuction.m)
%  Modified: 12 Dec  18  
%  Modified: 14 Dec  18  (renamed from HIsimFastGC_MkTableGain)  
%  Modified: 8 Dec 2019  %HIsimFastGC_MkCmpnstGain2mfile(TableGain)����
% 
%  Note: 14 Dec 18
%  �����ƒ������邽�߂�Gain 
%  HIsimFastGC_CmpnstGain.mat ���v�Z
% 
%  Note: 8 Dec 19
%  �R���p�C���łŁA����mat file�̈������ʓ|�Ȃ̂ŁAm-file�ɕϊ�����v���O����
%  HIsimFastGC_MkCmpnstGain2mfile(TableGain)����
%  
%
function [TableGain] = HIsimFastGC_MkCmpnstGain(SwGetName),

Mfn = which(eval('mfilename')); % directory of this m-file
TableGain.Dir = [ fileparts(Mfn) '/' ];
TableGain.Name = 'HIsimFastGC_CmpnstGain.mat' ;
TableGain.Note = 'IT, 14 Dec 18';

if nargin == 1 & SwGetName == 1, return; end;  % SwGetName==1�̎��̓t�@�C���������Ԃ��B

if exist([TableGain.Dir TableGain.Name]) > 0,
    disp([TableGain.Name ' exist. -- Overwrite?']);
    disp(['Return to OK >  ']);
    pause
end;

%%%%%%%%%%%%%%%%%%%
% �␳����Gain�̎Z�o������B
% Table������āA�⊮����l�����߂�B
%
ParamHI.AudiogramNum = NaN; % �蓮�ݒ�
ParamHI.SPLdB_CalibTone = 80;
ParamHI.SrcSndSPLdB = 0; % SPL0dB�Œ��ׂāA����gain�ō��킹���ށB
ParamHI.SwGUIbatch = 'Batch';
[ParamHI] = HIsimFastGC_InitParamHI(ParamHI); % ParamHI��load

%%%%%%%%%%%%%%%%%%%
% �T�C���g�̉������x���E���g���ق�
fs = 48000;  
Tdur = 0.2;% in sec
LenSnd = Tdur*fs;

%TableGain.CmprsList = [100 50 0];
% TableGain.CmprsList = [0:5:100];
TableGain.CmprsList = [100 67 50 33 0]; % ����ȊOdefault�ł͎��Ȃ��B
TableGain.HLdBList = [-5:5:80];
TableGain.FaudgramList =  ParamHI.FaudgramList;

SrcSndLeveldB = [];
HIsimSndLeveldB = [];

for nfc= 1:length(TableGain.FaudgramList)
    fc = TableGain.FaudgramList(nfc);

    SndIn = TaperWindow(LenSnd,'han',0.005*fs).*sin(2*pi*fc*(0:Tdur*fs-1)/fs);
    SndIn = SndIn(:)'; 

    for Cmprs = TableGain.CmprsList
        ParamHI.getComp = Cmprs; % 100%�\��
        nCmprs = find(Cmprs == TableGain.CmprsList);
        
        for nHL = 1:length(TableGain.HLdBList)  
            HLdB = TableGain.HLdBList(nHL);
            ParamHI.HearingLevelVal =  HLdB*ones(1,7);
            [HIsimSnd,SrcSnd, ParamHIbatch] = HIsimBatch(SndIn, ParamHI) ;
            BiasDigital2SPLdB = ParamHI.SPLdB_CalibTone - ParamHIbatch.CalibTone.RMSDigitalLeveldB;
 
            SrcSndLeveldB(nCmprs,nHL,nfc) = 20*log10(sqrt(mean(SrcSnd.^2)))+BiasDigital2SPLdB; %
            HIsimSndLeveldB(nCmprs, nHL,nfc) = 20*log10(sqrt(mean(HIsimSnd.^2)))+BiasDigital2SPLdB;
            HIsimSndLeveldB_DiffHL(nCmprs, nHL,nfc) = HIsimSndLeveldB(nCmprs, nHL,nfc) + HLdB;
            CmprsMeshgrid(nCmprs,nHL,nfc) = Cmprs;
            HLdBMeshgrid(nCmprs,nHL,nfc) = HLdB;
            FaudgramMeshgrid(nCmprs,nHL,nfc) = fc;

            % �Ⴂ�����邩���m�F
            if (ParamHIbatch.SPLdB_CalibTone -  ParamHI.SPLdB_CalibTone) ~= 0 || ...
                    (ParamHIbatch.SrcSndSPLdB - ParamHI.SrcSndSPLdB) ~=0
                error('Something wrong');
            end;
        end;
        
    end;
 
end;
 
%%
HIsimSndLeveldB_DiffHL

%%
TableGain.ParamHI = ParamHI;
TableGain.CmprsMeshgrid         = CmprsMeshgrid;
TableGain.HLdBMeshgrid          = HLdBMeshgrid;
TableGain.FaudgramMeshgrid  = FaudgramMeshgrid;
TableGain.HIsimSndLeveldB     = HIsimSndLeveldB;
TableGain.HIsimSndLeveldB_DiffHL = HIsimSndLeveldB_DiffHL;
TableGain.BiasDigital2SPLdB   = BiasDigital2SPLdB;

save([TableGain.Dir  TableGain.Name],'TableGain');

return;


%% %%%%%%%%%%%%%%%%%%
%  �Q�l�@
%%%%%%%%%%%%%%%%%%%%


%%
%%% 3�������g����Ȃ�A�Q�����⊮���g���K�v�Ȃ������B�����A�A�A
%%%  Faudgram���Ƃɏ������Ⴄ�̂ŁA������ɂ���A1���g�����Ƃɏo�����ƁB
%%% �܂��Ac version�̂��߂ɁA2�����ŏ����������ǂ��C������B
%%%
%Vq = interp2(X,Y,V,Xq,Yq)

for nfc= 1:length(TableGain.FaudgramList)
    fc = TableGain.FaudgramList(nfc);
    GainMtrx = squeeze(TableGain.HIsimSndLeveldB_DiffHL(:,:,nfc));
    X = squeeze(TableGain.HLdBMeshgrid(:,:,nfc));
    Y = squeeze(TableGain.CmprsMeshgrid(:,:,nfc));
    qCmprs = 50;
    qHLdB = 10;
    Gain4Cmpnst2(nfc) = interp2(X,Y,GainMtrx,qHLdB,qCmprs)
    nCmprs = find(TableGain.CmprsList== qCmprs);
    nHLdB  = find(TableGain.HLdBList== qHLdB);
    aa(nfc) = GainMtrx(nCmprs,nHLdB)

end;
Gain4Cmpnst2



%% 3�����⊮���\. �ȉ��̎��ŕ␳�̂��߂�gain�v�Z�\�B
[LenCmprs,LenHLdB,LenFaud] = size(TableGain.HIsimSndLeveldB_DiffHL);
for nfc = 1:length(TableGain.FaudgramList);
    fc = TableGain.FaudgramList(nfc);
    ValGain = TableGain.HIsimSndLeveldB_DiffHL;
    X = TableGain.HLdBMeshgrid;
    Y = TableGain.CmprsMeshgrid;
    Z = TableGain.FaudgramMeshgrid;
    Gain4Cmpnst(nfc) = interp3(X,Y,Z,ValGain,10,50,fc)
    ValGain(2,2,nfc)
end;
Gain4Cmpnst

%%%%  m-file�ɕϊ�������̂��@����Ă����@8 Dec 2019 %%%%  
HIsimFastGC_MkCmpnstGain2mfile(TableGain);




