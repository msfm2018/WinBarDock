#include <Windows.h>
#include <stdio.h>

#include <netlistmgr.h>
#pragma comment(lib, "Ole32.lib")


//�ò��ִ����������Ƿ����ӵ������������û�����ӵ���������isConnected == VARIANT_FALSE��������Ȼ���ӵ���������������ͨ�� GetConnectivity ��ȡ������״̬������ connectedStatus ����Ϊ 2����ʾ��������ӵ������������������û�����ӵ���������
//
//�����־�����ÿ������ں����Ĵ�����ʾ�������Ӵ��ڡ��ǻ�����״̬�������磬�����Ǿ���������������

__declspec(dllexport) int IsConnectedToInternet()
{
    int connectedStatus = 0;
    HRESULT hr = S_FALSE;

    hr = CoInitialize(NULL);
    if (SUCCEEDED(hr))
    {
        INetworkListManager* pNetworkListManager;
        hr = CoCreateInstance(&CLSID_NetworkListManager, NULL, CLSCTX_ALL, &IID_INetworkListManager, (void**)&pNetworkListManager);
          if (SUCCEEDED(hr))
        {
            NLM_CONNECTIVITY nlmConnectivity = NLM_CONNECTIVITY_DISCONNECTED;
            VARIANT_BOOL isConnected = VARIANT_FALSE;
            hr = pNetworkListManager->lpVtbl->get_IsConnectedToInternet(pNetworkListManager, &isConnected);
            if (SUCCEEDED(hr))
            {
                if (isConnected == VARIANT_TRUE)
                    connectedStatus = 1;
                else
                    connectedStatus = 0;
            }
            if (isConnected == VARIANT_FALSE && SUCCEEDED(pNetworkListManager->lpVtbl->GetConnectivity(pNetworkListManager, &nlmConnectivity)))
            {
                if (nlmConnectivity & (NLM_CONNECTIVITY_IPV4_LOCALNETWORK | NLM_CONNECTIVITY_IPV4_SUBNET | NLM_CONNECTIVITY_IPV6_LOCALNETWORK | NLM_CONNECTIVITY_IPV6_SUBNET))
                {
                    connectedStatus = 2;
                }
            }
            pNetworkListManager->lpVtbl->Release(pNetworkListManager);
        }
        CoUninitialize();
    }
    return connectedStatus;
}