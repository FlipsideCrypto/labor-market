/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { ethers } from "ethers";
import {
  FactoryOptions,
  HardhatEthersHelpers as HardhatEthersHelpersBase,
} from "@nomiclabs/hardhat-ethers/types";

import * as Contracts from ".";

declare module "hardhat/types/runtime" {
  interface HardhatEthersHelpers extends HardhatEthersHelpersBase {
    getContractFactory(
      name: "Initializable",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Initializable__factory>;
    getContractFactory(
      name: "ERC1155",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC1155__factory>;
    getContractFactory(
      name: "IERC1155MetadataURI",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC1155MetadataURI__factory>;
    getContractFactory(
      name: "IERC1155",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC1155__factory>;
    getContractFactory(
      name: "IERC1155Receiver",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC1155Receiver__factory>;
    getContractFactory(
      name: "ERC20",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC20__factory>;
    getContractFactory(
      name: "IERC20Metadata",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC20Metadata__factory>;
    getContractFactory(
      name: "IERC20",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC20__factory>;
    getContractFactory(
      name: "ERC165",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC165__factory>;
    getContractFactory(
      name: "IERC165",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IERC165__factory>;
    getContractFactory(
      name: "NBadgeAuth",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.NBadgeAuth__factory>;
    getContractFactory(
      name: "ScalableEnforcement",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ScalableEnforcement__factory>;
    getContractFactory(
      name: "NBadgeAuthInterface",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.NBadgeAuthInterface__factory>;
    getContractFactory(
      name: "EnforcementCriteriaInterface",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.EnforcementCriteriaInterface__factory>;
    getContractFactory(
      name: "LaborMarketFactoryInterface",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.LaborMarketFactoryInterface__factory>;
    getContractFactory(
      name: "LaborMarketInterface",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.LaborMarketInterface__factory>;
    getContractFactory(
      name: "LaborMarket",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.LaborMarket__factory>;
    getContractFactory(
      name: "LaborMarketFactory",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.LaborMarketFactory__factory>;
    getContractFactory(
      name: "ERC1155FreeMint",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC1155FreeMint__factory>;
    getContractFactory(
      name: "ERC20FreeMint",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.ERC20FreeMint__factory>;

    getContractAt(
      name: "Initializable",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.Initializable>;
    getContractAt(
      name: "ERC1155",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC1155>;
    getContractAt(
      name: "IERC1155MetadataURI",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC1155MetadataURI>;
    getContractAt(
      name: "IERC1155",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC1155>;
    getContractAt(
      name: "IERC1155Receiver",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC1155Receiver>;
    getContractAt(
      name: "ERC20",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC20>;
    getContractAt(
      name: "IERC20Metadata",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC20Metadata>;
    getContractAt(
      name: "IERC20",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC20>;
    getContractAt(
      name: "ERC165",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC165>;
    getContractAt(
      name: "IERC165",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.IERC165>;
    getContractAt(
      name: "NBadgeAuth",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.NBadgeAuth>;
    getContractAt(
      name: "ScalableEnforcement",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ScalableEnforcement>;
    getContractAt(
      name: "NBadgeAuthInterface",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.NBadgeAuthInterface>;
    getContractAt(
      name: "EnforcementCriteriaInterface",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.EnforcementCriteriaInterface>;
    getContractAt(
      name: "LaborMarketFactoryInterface",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.LaborMarketFactoryInterface>;
    getContractAt(
      name: "LaborMarketInterface",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.LaborMarketInterface>;
    getContractAt(
      name: "LaborMarket",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.LaborMarket>;
    getContractAt(
      name: "LaborMarketFactory",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.LaborMarketFactory>;
    getContractAt(
      name: "ERC1155FreeMint",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC1155FreeMint>;
    getContractAt(
      name: "ERC20FreeMint",
      address: string,
      signer?: ethers.Signer
    ): Promise<Contracts.ERC20FreeMint>;

    // default types
    getContractFactory(
      name: string,
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<ethers.ContractFactory>;
    getContractFactory(
      abi: any[],
      bytecode: ethers.utils.BytesLike,
      signer?: ethers.Signer
    ): Promise<ethers.ContractFactory>;
    getContractAt(
      nameOrAbi: string | any[],
      address: string,
      signer?: ethers.Signer
    ): Promise<ethers.Contract>;
  }
}
