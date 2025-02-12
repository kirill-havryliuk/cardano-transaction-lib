-- | A module with Wallet-related functionality.
module Contract.Wallet
  ( mkKeyWalletFromPrivateKeys
  , withKeyWallet
  , getNetworkId
  , getUnusedAddresses
  , getChangeAddress
  , getRewardAddresses
  , getWallet
  , signData
  , module Contract.Address
  , module Contract.Utxos
  , module Deserialization.Keys
  , module Wallet
  , module Ctl.Internal.Wallet.Key
  , module Ctl.Internal.Wallet.KeyFile
  , module Ctl.Internal.Wallet.Spec
  ) where

import Prelude

import Contract.Address (getWalletAddress, getWalletCollateral)
import Contract.Monad (Contract, ContractEnv, wrapContract)
import Contract.Utxos (getWalletUtxos) as Contract.Utxos
import Control.Monad.Reader (local)
import Ctl.Internal.Deserialization.Keys (privateKeyFromBytes) as Deserialization.Keys
import Ctl.Internal.QueryM
  ( getChangeAddress
  , getNetworkId
  , getRewardAddresses
  , getUnusedAddresses
  , getWallet
  , signData
  ) as QueryM
import Ctl.Internal.Serialization.Address (Address, NetworkId)
import Ctl.Internal.Types.RawBytes (RawBytes)
import Ctl.Internal.Wallet
  ( Wallet(Gero, Nami, Flint, Lode, Eternl, KeyWallet)
  , WalletExtension
  , apiVersion
  , icon
  , isEnabled
  , isEternlAvailable
  , isFlintAvailable
  , isGeroAvailable
  , isLodeAvailable
  , isNamiAvailable
  , isWalletAvailable
  , name
  , walletToWalletExtension
  ) as Wallet
import Ctl.Internal.Wallet (Wallet(KeyWallet), mkKeyWallet)
import Ctl.Internal.Wallet.Cip30 (DataSignature)
import Ctl.Internal.Wallet.Key (KeyWallet, privateKeysToKeyWallet) as Wallet
import Ctl.Internal.Wallet.Key
  ( PrivatePaymentKey(PrivatePaymentKey)
  , PrivateStakeKey(PrivateStakeKey)
  )
import Ctl.Internal.Wallet.KeyFile (formatPaymentKey, formatStakeKey)
import Ctl.Internal.Wallet.Spec
  ( PrivatePaymentKeySource(PrivatePaymentKeyFile, PrivatePaymentKeyValue)
  , PrivateStakeKeySource(PrivateStakeKeyFile, PrivateStakeKeyValue)
  , WalletSpec
      ( UseKeys
      , ConnectToNami
      , ConnectToGero
      , ConnectToFlint
      , ConnectToLode
      , ConnectToEternl
      )
  )
import Data.Lens (Lens, (.~))
import Data.Lens.Common (simple)
import Data.Lens.Iso.Newtype (_Newtype)
import Data.Lens.Record (prop)
import Data.Maybe (Maybe(Just))
import Type.Proxy (Proxy(Proxy))

getNetworkId :: forall (r :: Row Type). Contract r NetworkId
getNetworkId = wrapContract QueryM.getNetworkId

getUnusedAddresses :: forall (r :: Row Type). Contract r (Array Address)
getUnusedAddresses = wrapContract QueryM.getUnusedAddresses

getChangeAddress :: forall (r :: Row Type). Contract r (Maybe Address)
getChangeAddress = wrapContract QueryM.getChangeAddress

getRewardAddresses :: forall (r :: Row Type). Contract r (Array Address)
getRewardAddresses = wrapContract QueryM.getRewardAddresses

signData
  :: forall (r :: Row Type)
   . Address
  -> RawBytes
  -> Contract r (Maybe DataSignature)
signData address dat = wrapContract (QueryM.signData address dat)

getWallet :: forall (r :: Row Type). Contract r (Maybe Wallet)
getWallet = wrapContract QueryM.getWallet

withKeyWallet
  :: forall (r :: Row Type) (a :: Type)
   . Wallet.KeyWallet
  -> Contract r a
  -> Contract r a
withKeyWallet wallet action = do
  let
    setUpdatedWallet :: ContractEnv r -> ContractEnv r
    setUpdatedWallet =
      simple _Newtype <<< _runtime <<< _wallet .~
        (Just (KeyWallet wallet))
  local setUpdatedWallet action
  where
  _wallet
    :: forall x rest. Lens { wallet :: x | rest } { wallet :: x | rest } x x
  _wallet = prop (Proxy :: Proxy "wallet")

  _runtime
    :: forall x rest. Lens { runtime :: x | rest } { runtime :: x | rest } x x
  _runtime = prop (Proxy :: Proxy "runtime")

mkKeyWalletFromPrivateKeys
  :: PrivatePaymentKey -> Maybe PrivateStakeKey -> Wallet
mkKeyWalletFromPrivateKeys = mkKeyWallet
